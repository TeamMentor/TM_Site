request            = null
Jade_Service       = null
Article_Controller = null

class Api_Controller

  dependencies: ->
    request      = require 'request'

  constructor: (req, res)->
    @.dependencies()
    @.req                = req
    @.res                = res
    @.graphDb_Port       = global.config?.tm_graph?.port
    @.graphDb_Server     = "http://localhost:#{@.graphDb_Port}"

  api_Proxy: ()=>
    url = @.graphDb_Server +  @.req.url
    @.req.pipe(request(url)).pipe @.res

Api_Controller.register_Routes =  (app)=>
  app.use '/api'                , (req, res)-> new Api_Controller(req, res).api_Proxy()
  @

module.exports = Api_Controller