cookieName          = 'X2ZpbmdlcnByaW50' #_fingerprint on base 64
Jade_Service        = null
Nedb                = null

class Anonymous_Service
  dependencies: ()->
    Nedb                = require('nedb')
    Jade_Service        = require('../services/Jade-Service')
    @.crypto            = require 'crypto'

  constructor:(req, res)->
    @.dependencies()
    @.req                       = req
    @.res                       = res
    @.filename                  = './.tmCache/_anonymousVisits'
    @.db                        = new Nedb({ filename: @.filename, autoload: true })
    @.anonymousArticlesAllowed  = global.config?.tm_design.anonymousArticlesAllowed
    @.now                       = new Date(Date.now())

  setup: (req,res)->
    @.db.ensureIndex { fieldName: '_fingerprint', unique: true },(err)->
      if err
        console.log "Error building index on _fingerprint field: " + err
    if(not @.anonymousArticlesAllowed)
      console.log("Error number of anonymous articles is not defined.")
    @.cleanupExpiredRecords()

  save: (doc,callback)->
      @.db.insert doc, (err,doc) ->
        if err
          console.log 'Error saving to datastore with the following error: ' + err
        callback()

  update: (query,update,options,callback) ->
    @.db.update query,update,options,(err,doc) =>
      if err
        console.log 'Error updating record in datastore: ' + err
        callback(null)
      @.db.persistence.compactDatafile()
      callback(doc)

  cleanupExpiredRecords:()->
    now = new Date()
    expirationDate = now.setDate(now.getDate() - 30)

    console.log "\nCleaning expired records.."

    @.db.remove { creationDate: { $lt: new Date(expirationDate) } },{ multi: true },(err,numRemoved)->
      if err
        console.log "\nError removing records older than 30 days: " + err
      else
        console.log "\n  -------------------------------------- \n"
        console.log "Number of expired records removed was: " + numRemoved

  findOne: (search,callback)->
    @.db.findOne search,(err,doc)->
      if err
        console.log 'Error trying to find a record for: ' + search
        console.log 'Error is: ' + err
      callback doc

  remoteIp: () ->
    ipAddr = @.req.headers["x-forwarded-for"]
    if (ipAddr)
      ipAddr = @.req.headers['x-forwarded-for'].split(',')[0]
    else
      ipAddr = @.req.connection.remoteAddress
    return ipAddr

  computeFingerPrint: () ->
    shasum = @.crypto.createHash('sha256');
    for i of @.req.headers
      shasum.update(@.req.headers[i])

    return shasum.digest('hex')

  redirectToLoginPage:() ->
    @.req.session.redirectUrl = @.req.url
    @.res.status(403)
    .send(new Jade_Service().render_Jade_File('guest/login-required.jade'))

  checkAuth:(next)->
    if @.req?.session?.username
      return next()

    if not @.anonymousArticlesAllowed
      console.log("No anonymous articles specified.Redirecting to the login page ")
      return @redirectToLoginPage()


    fingerprint = @.req.cookies?[cookieName]
    if (not fingerprint)
      fingerprint = @computeFingerPrint()
    @findOne {_fingerprint:fingerprint},(data)=>
      if (not data)
        @findOne {remoteIp:@remoteIp()}, (data)=>
          if (not data)
            counter = parseInt(@.anonymousArticlesAllowed)-1
            doc = {"_fingerprint":fingerprint,"remoteIp": @remoteIp(),"articleCount":counter,"creationDate":new Date(@.now)}
            @.res.cookie(cookieName,fingerprint, { expires: new Date(Date.now() + 900000), httpOnly: true });
            @save doc,(callback)->
              return next()
          else
            if(data? && data.articleCount > 0)
              articlesAllowed = data.articleCount
              articlesAllowed = parseInt(articlesAllowed)-1;
              @update {"remoteIp": @remoteIp()},{$set:{"articleCount": articlesAllowed }}, {}, (callback)->
                return next()
            else
              return @redirectToLoginPage()
      else
        if(data? && data.articleCount > 0)
          articlesAllowed = data.articleCount
          articlesAllowed = parseInt(articlesAllowed)-1;
          @update {"_fingerprint": fingerprint},{$set:{"articleCount": articlesAllowed }}, {}, (callback)=>
            return next()
        else
          return @redirectToLoginPage()

  module.exports =Anonymous_Service

