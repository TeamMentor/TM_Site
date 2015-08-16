request            = null
Jade_Service       = null
Article_Controller = null
Router             = null

class API_Controller

  @.LOGIN_FAIL_MESSAGE = { error: 'user login required'}

  dependencies: ->
    request      = require 'request'
    {Router}     = require 'express'


  constructor: ()->
    @.dependencies()
    @.graphDb_Port       = global.config?.tm_graph?.port
    @.graphDb_Server     = "http://localhost:#{@.graphDb_Port}"

  api_Proxy: (req,res)=>
    url = @.graphDb_Server +  req.url
    if req.method is 'GET'                                  # only GET requests are supported
      if req.query['pretty'] is ''                          # if a ?pretty to the request url (show a formatted version of the data)
        url.GET_Json (data)->                               #   make a GET request to the graphDB url
          res.send "<pre>" + data.json_Pretty() + "</pre>"  #   send the data wrapped in a <pre> tag so that it shows ok in a browser
      else
        req.pipe(request(url)).pipe res                     # pipe GET and POST requests between cli

  check_Auth: (req,res,next)=>
    if req?.session?.username and req?.url?.not_Contains '/user'
      return next()

    res.json API_Controller.LOGIN_FAIL_MESSAGE

  routes: =>
    router = new Router()
    router.use '/api'        , @.check_Auth, @.api_Proxy    # router.get '/api' was not working

module.exports = API_Controller