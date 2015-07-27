cookieName          = 'X2ZpbmdlcnByaW50' #_fingerprint on base 64
Jade_Service        = null
class Anonymous_Service

  constructor:(req, res)->
    @.req               = req
    @.res               = res
    @.crypto            = require 'crypto'
    Jade_Service       = require('../services/Jade-Service')
  remoteIp: () ->
    ipAddr = @.req.headers["x-forwarded-for"]
    if (ipAddr)
      ipAddr = @.req.headers['x-forwarded-for'].split(',')[0]
    else
      ipAddr = @.req.connection.remoteAddress
    return ipAddr

  computeFingerPrint: () ->
    shasum = @.crypto.createHash('sha1');
    for i of @.req.headers
      shasum.update(@.req.headers[i])

    return shasum.digest('hex')

  checkAuth:(next)->
    #Case 1, user already authenticated.
    if @.req?.session?.username
      return next()

    if @.req.url is '/'
      @.res.redirect '/index.html'
    else
      @.req.session.redirectUrl = @.req.url
      @.res.status(403)
      .send(new Jade_Service().render_Jade_File('guest/login-required.jade'))

  module.exports =Anonymous_Service

