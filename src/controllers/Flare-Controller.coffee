request = null

class Flare_Controller

  dependencies: ->
    request = require 'request'

  constructor: (req, res)->
    @.dependencies()

    @.req              = req
    @.res              = res
    @.graphDb_Port   = global.config?.tm_graph?.port
    @.graphDb_Server = "http://localhost:#{@.graphDb_Port}"

  api_Proxy: ()=>
    url = @.graphDb_Server +  @.req.url
    @.req.pipe(request(url)).pipe @.res

Flare_Controller.register_Routes =  (app)=>
  app.use '/api'      , (req, res)-> new Flare_Controller(req, res).api_Proxy()
  @

module.exports = Flare_Controller