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
    @.filename          = @.options.filename || './.tmCache/_anonymousVisits' #"_session_Data"
    @.db                = new Nedb(@.filename)
    Jade_Service        = require('../services/Jade-Service')

  setup: (req,res)->
    @.db.loadDatabase =>
      @.db.persistence.setAutocompactionInterval(30 * 1000) # set to 30s

  save: (doc)->
    @.db.insert doc, (err) ->
      if err
        console.log('Error saving data')

  findByFingerPrint: (search)->
    @.db.find search , (error, data)->
      if error
        console.log ('Error')
      return data

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

  checkAuth:(next)->
    #Case 1, user already authenticated.
    if @.req?.session?.username
      return next()
    fingerprint = @.req.cookie['X2ZpbmdlcnByaW50']
    if (fingerprint)
      data = @findByFingerPrint(fingerprint)
      if(!data)
        data = @findByFingerPrint(@remoteIp())
        if (!data)
          #create cookie, create
    else


    if @.req.url is '/'
      @.res.redirect '/index.html'
    else
      @.req.session.redirectUrl = @.req.url
      @.res.status(403)
      .send(new Jade_Service().render_Jade_File('guest/login-required.jade'))

  module.exports =Anonymous_Service

