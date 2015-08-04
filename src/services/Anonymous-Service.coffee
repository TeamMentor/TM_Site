Jade_Service        = null
Nedb                = null
config              = require '../config'

class Anonymous_Service
  dependencies: ()->
    Nedb                = require 'nedb'
    Jade_Service        = require '../services/Jade-Service'
    @.crypto            = require 'crypto'

  constructor: (req, res) ->
    @.dependencies()
    @.req                       = req
    @.res                       = res
    @.filename                  = './.tmCache/_anonymousVisits'
    @.db                        = new Nedb({ filename: @.filename, autoload: true })
    @.anonymousConfig           = config?.options?.anonymousService
    @.now                       = new Date(Date.now())

  setup: ()->
    @.db.ensureIndex { fieldName: '_fingerprint', unique: true },(err)->
      if err
        console.log "Error building index on _fingerprint field: " + err
    if(not @.anonymousConfig.allowAnonymousArticles)
      console.log("Error number of anonymous articles is not defined.")
    @.cleanupExpiredRecords()

  save: (record,callback)->
      @.db.insert record, (err,doc) ->
        if err
          console.log 'Error saving to datastore with the following error: ' + err
        callback()

  update: (query,update,options,callback) ->
    @.db.update query,update,options,(err,doc) =>
      if err
        console.log 'Error updating record in datastore: ' + err
        callback null
      @.db.persistence.compactDatafile()
      callback doc

  cleanupExpiredRecords: ()->
    now = new Date()
    expirationDate = now.setDate(now.getDate() - @.anonymousConfig.expirationDays)
    console.log "Cleaning expired records from _anonymousVisits datastore..."
    @.db.remove { creationDate: { $lt: new Date(expirationDate) } },{ multi: true },(err,numRemoved)->
      if err
        console.log "Error removing records older than " + @.anonymousConfig.expirationDays + "days: " + err
      else
        console.log "Number of expired _anonymousVisits records removed: " + numRemoved

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

  createCookie: (ipAddr,fingerprint,callback) ->
    counter = parseInt(@.anonymousConfig.allowedArticles)-1
    record = { "_fingerprint":fingerprint,"remoteIp":ipAddr,"articleCount":counter,"creationDate":new Date(@.now) }
    @.res.cookie(@.anonymousConfig.cookieName,fingerprint, { expires: new Date(Date.now() + 900000), httpOnly: true });
    @save record,(doc)=>
      callback()

  updateArticlesAllowed: (field,data,callback) ->
    if(data? && data.articleCount > 0)
      articlesAllowed = data.articleCount
      articlesAllowed = parseInt(articlesAllowed)-1;
      @update field,{ $set:{ "articleCount": articlesAllowed }}, {}, (doc)=>
        callback doc
    else
      return @redirectToLoginPage()

  redirectToLoginPage: () ->
    @.req.session.redirectUrl = @.req.url
    @.res.status(403)
    .send(new Jade_Service().render_Jade_File('guest/login-required.jade'))

  checkAuth: (next) ->
    if @.req?.session?.username
      return next()
    if not @.anonymousConfig.allowAnonymousArticles
      console.log "No anonymous articles specified. Redirecting to the login page. "
      return @redirectToLoginPage()
    fingerprint = @.req.cookies?[@.anonymousConfig.cookieName]
    if (not fingerprint)
      fingerprint = @computeFingerPrint()
    @findOne {_fingerprint:fingerprint},(data)=>
      if (not data)
        ipAddr = @remoteIp()
        @findOne { remoteIp:ipAddr }, (data)=>
          if (not data)
            @createCookie ipAddr,fingerprint,(callback)=>
              return next()
          else
            @updateArticlesAllowed { remoteIp:ipAddr },data,(callback)=>
              return next()
      else
        @updateArticlesAllowed { _fingerprint:fingerprint },data,(callback)=>
          return next()

  module.exports = Anonymous_Service

