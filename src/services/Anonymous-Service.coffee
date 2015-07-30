cookieName          = 'X2ZpbmdlcnByaW50' #_fingerprint on base 64
Jade_Service        = null
Nedb                = null

class Anonymous_Service
  dependencies: ()->
    Nedb            = require('nedb')
    Jade_Service        = require('../services/Jade-Service')
    @.crypto            = require 'crypto'

  constructor:(req, res)->
    @.dependencies()
    @.req               = req
    @.res               = res
    @.filename          = './.tmCache/_anonymousVisits'
    @.db                = new Nedb(@.filename)
    @.now               = new Date(Date.now())
    @setup()

  setup: (req,res)->
    @.db.loadDatabase =>
      #@.db.persistence.setAutocompactionInterval(30 * 1000) # set to 30s

  save: (doc,callback)->
    @.db.loadDatabase =>
      @.db.insert doc, (err,doc) ->
        if err
          console.log('Error saving data')
        callback()

  update: (query,update,options,callback) ->
    @.db.update query,update,options,(error,doc) =>
      if error
        callback(null)
      @.db.persistence.compactDatafile()
      callback(doc)

  findOne: (search,callback)->
    @.db.findOne search,(err,doc)->
      if err
        console.log 'Error trying to find a record.'
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

    now = new Date()
    expirationDate = now.setDate(now.getDate() - 30)

    @.db.remove { creationDate: { $lt: new Date(expirationDate) } },{ multi: true },(err,numRemoved)->
      if err
        console.log "\nError removing records older than 30 days."
      else
        console.log "\n  -------------------------------------- \n"
        console.log "Number of expired records removed was: " + numRemoved

    fingerprint = @.req.cookies?['X2ZpbmdlcnByaW50']

    if (not fingerprint)
      fingerprint = @computeFingerPrint()

    @findOne {_fingerprint:fingerprint},(data)=>
      if (not data)
        @findOne {remoteIp:@remoteIp()}, (data)=>
          if (not data)
            doc = {"_fingerprint":fingerprint,"remoteIp": @remoteIp(),"articleCount":5,"creationDate":new Date(@.now)}
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

