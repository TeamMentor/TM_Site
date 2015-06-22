request            = null
Jade_Service       = null
Article_Controller = null

http               = require 'http'
Router             = null



class API_Controller

  @.LOGIN_FAIL_MESSAGE = { error: 'user login required'}

  dependencies: ->
    #http         =
    request      = require 'request'
    {Router}     = require 'express'

  constructor: ()->
    @.dependencies()
    @.graphDb_Port       = global.config?.tm_graph?.port
    @.graphDb_Server     = "http://localhost:#{@.graphDb_Port}"

  api_Proxy: (req,res)=>
    if req.user_Logged_In()
      url = @.graphDb_Server +  req.url
      req.pipe(request(url)).pipe res
    else
      res.json { error: 'user login required'}

  check_Auth: (req,res,next)=>
    if req?.session?.username
      return next()
    res.json API_Controller.LOGIN_FAIL_MESSAGE

  routes: =>
    router = new Router()
    router.use '/api', @.check_Auth, @.api_Proxy

  #register_Routes:  (app)=>
  #  app.use '/api', @.api_Proxy
  #  @

module.exports = API_Controller