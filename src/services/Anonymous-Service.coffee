cookieName          = 'X2ZpbmdlcnByaW50' #_fingerprint on base 64
Jade_Service        = null
Nedb                = null

class Anonymous_Service
  dependencies: ()->
    Nedb            = require('nedb')

  constructor:(req, res)->
    @.dependencies()
    @.req               = req
    @.res               = res
    @.crypto            = require 'crypto'
    @.filename          = './.tmCache/_anonymousVisits'
    Jade_Service        = require('../services/Jade-Service')
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

  updateAllowedArticles : (currentDoc, newDoc) ->
    @.db.update currentDoc, newDoc, {}, (err, numReplaced)->
      if (err)
        console.log('Error updating user')
      return

  update: (query,update,options,callback) ->
    @.db.update query,update,options,(error,doc) =>
      if error
        callback(null)
      @.db.persistence.compactDatafile()
      callback(doc)

  findByFingerPrint: (fingerprint,callback)->
    @.db.findOne {_fingerprint:fingerprint},(error, document)->
      if error
        console.log ('Error')
      callback document

  findByRemoteIp: (remoteIp,callback)->
    @.db.findOne {remoteIp:remoteIp},(error, document)->
      if error
        console.log ('Error')
      callback document

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
    console.log "expirationDate is: " + expirationDate

    @.db.find { creationDate: { $lt: expirationDate } },(err,docs)->
      if err
        console.log "\nError finding records older than 30 days."
      else
        console.log "docs are: \n" + docs
        console.log "\n --------------------------------------- \n"
        docs.forEach (element,index)->
          console.log "\nelement is: " + element
          console.log "\ndoc is: " + index
        return docs

    ###
    @.db.remove { "creationDate:$$date": { $lt: expirationDate } },{ multi: true },(err,numRemoved)->
      if err
        console.log "\nError removing records older than 30 days."
      else
        console.log "\n  -------------------------------------- \n"
        console.log "Number removed was: " + numRemoved
        console.log 1435674695210 > 1432962110000
        return numRemoved
    ###
    fingerprint = @.req.cookies?['X2ZpbmdlcnByaW50']

    if (not fingerprint)
      fingerprint = @computeFingerPrint()

    @findByFingerPrint fingerprint,(data)=>
      if (not data)
        @findByRemoteIp @remoteIp(), (data)=>
          console.log("Fingerprint do not match then finding by remote IP " )
          if (not data)
            doc = {"_fingerprint":fingerprint,"remoteIp": @remoteIp(),"articleCount":5,"creationDate":@.now}
            @.res.cookie(cookieName,fingerprint, { expires: new Date(Date.now() + 900000), httpOnly: true });
            @save doc,(callback)->
              return next()
          else
            if(data? && data.articleCount > 0)
              articlesAllowed = data.articleCount
              articlesAllowed = parseInt(articlesAllowed)-1;
              @update {"remoteIp": @remoteIp()},{$set:{"articleCount": articlesAllowed }}, {}, (callback)->
                console.log("Updated..")
                return next()
            else
              return @redirectToLoginPage()
      else
        if(data? && data.articleCount > 0)
          articlesAllowed = data.articleCount
          articlesAllowed = parseInt(articlesAllowed)-1;
          console.log("Here")
          @update {"_fingerprint": fingerprint},{$set:{"articleCount": articlesAllowed }}, {}, (callback)=>
            console.log("Updated..")
            return next()
        else
          console.log("Sorry you are not allowed to see more articles ! " + fingerprint)
          return @redirectToLoginPage()

  module.exports =Anonymous_Service

