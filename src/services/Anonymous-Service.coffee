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
    @setup()

  setup: (req,res)->
    @.db.loadDatabase =>
      @.db.persistence.setAutocompactionInterval(30 * 1000) # set to 30s

  save: (doc)->
    @.db.loadDatabase =>
      @.db.insert doc, (err,doc) ->
        if err
          console.log('Error saving data')
        console.log("Doc created " + doc)

  updateAllowedArticles : (currentDoc, newDoc) ->
    @.db.update currentDoc, newDoc, {}, (err, numReplaced) ->
      if (err)
        console.log('Error updating user')
      return

  update: (query,update,options) ->
    @.db.update query,update,options,(error) =>
      if error
        console.log 'Error updating article count for: ' + query
      return

  findByFingerPrint: (fingerprint,callback)->
    @.db.findOne {_fingerprint:fingerprint},(error, document)->
      if error
        console.log ('Error')
      callback document

  findByRemoteIp: (search)->
    @.db.find search , (error, data)->
      if error
        console.log ('Error')
      return data

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
    fingerprint = @.req.cookies?['X2ZpbmdlcnByaW50']

    if(fingerprint)
      console.log("Searching by Fingerprint")
      @findByFingerPrint fingerprint,(data)=>
        if(data? && data.articleCount > 0)
          articlesAllowed = data.articleCount
          articlesAllowed = parseInt(articlesAllowed)-1;
          console.log("Allowed to "  + articlesAllowed + " articles")
          @update {"_fingerprint": fingerprint},{$set:{"articleCount": articlesAllowed }}, {upsert:false}
          return next()
        else
          return @redirectToLoginPage()
    else
      fingerprint = @computeFingerPrint()
      doc = {"_fingerprint":fingerprint,"remoteIp": @remoteIp(),"articleCount":5}
      @.res.cookie(cookieName,fingerprint, { expires: new Date(Date.now() + 900000), httpOnly: true });
      @save(doc)
      return next()



  module.exports =Anonymous_Service

