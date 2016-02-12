request            = null
Jade_Service       = null
Article_Controller = null
Router             = null
Analytics_Service  = null

class API_Controller

  @.LOGIN_FAIL_MESSAGE = { error: 'user login required'}

  dependencies: ->
    request            = require 'request'
    {Router}           = require 'express'
    Analytics_Service  = require('../services/Analytics-Service')


  constructor: ()->
    @.dependencies()
    @.graphDb_Port       = global.config?.tm_graph?.port
    @.graphDb_Server     = "http://localhost:#{@.graphDb_Port}"

  api_Proxy: (req,res)=>
    url = @.graphDb_Server +  req.url
    if(req.url.contains('query_from_text_search'))
      textsearch = url.split('/').last().url_Decode()
      using new  Analytics_Service(req, res),->
        @.track("","","",textsearch,"Text Search")
        @.track()

    if req.method is 'GET'                                  # only GET requests are supported
      if req.query['pretty'] is ''                          # if a ?pretty to the request url (show a formatted version of the data)
        url.GET_Json (data)->                               #   make a GET request to the graphDB url
          res.send "<pre>" + data?.json_Pretty() + "</pre>"  #   send the data wrapped in a <pre> tag so that it shows ok in a browser
      else
        req.pipe(request(url)).pipe res                     # pipe GET and POST requests between cli

  check_Auth: (req,res,next)=>
    ###
      req.originalURL returns => /api/search/query_from_text_search/user%20enumeration
      req.url         return  => /search/query_from_text_search/user%20enumeration
      hence below evaluation uses req.originalURL
      This request should redirect to login page => http://localhost:12345/api/user/log_search_valid/a/b
    ###
    if req?.session?.username and req?.originalUrl?.not_Contains '/api/user/'
      #Expiration date logic goes here.
      now             = Date.now()
      expirationDate  = req.session?.sessionExpirationDate

      if (expirationDate? && (now >  expirationDate))  #Session is expired.
        req.session.destroy()
        return res.status(403).send(API_Controller.LOGIN_FAIL_MESSAGE)
      else
        return next()

      return next()

    res.status(403).send(API_Controller.LOGIN_FAIL_MESSAGE)

  routes: =>
    router = new Router()
    router.use '/api'        , @.check_Auth, @.api_Proxy    # router.get '/api' was not working

module.exports = API_Controller