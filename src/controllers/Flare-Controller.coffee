request            = null
Jade_Service       = null
Article_Controller = null

class Flare_Controller

  dependencies: ->
    request      = require 'request'
    Jade_Service = require('../services/Jade-Service')
    Article_Controller =  require './Article-Controller'

  constructor: (req, res)->
    @.dependencies()
    @.req                = req
    @.res                = res
    @.graphDb_Port       = global.config?.tm_graph?.port
    @.graphDb_Server     = "http://localhost:#{@.graphDb_Port}"
    @.jade_Service       = new Jade_Service()
    @.article_Controller = new Article_Controller(req,res)

  api_Proxy: ()=>
    url = @.graphDb_Server +  @.req.url
    @.req.pipe(request(url)).pipe @.res


  render_Page: (params)=>
    path = '../TM_Flare/' + @.req.params.page + '.jade'

    log @.jade_Service.cache_Enabled()
    @res.send @.jade_Service.render_Jade_File(path, params)

  show_Article: ()=>
    @.article_Controller.jade_Article = '../TM_Flare/article-new-window-view.jade'
    @.article_Controller.article()
    return
    article_Id = '17f790dedf10' #@.req.params.id
    "rendering article: #{article_Id}".log()
    @.req.params.page = 'article-new-window-view'
    @.render_Page article_Id


#../TM_Flare/article-new-window-view.jade



Flare_Controller.register_Routes =  (app)=>
  app.use '/api'                , (req, res)-> new Flare_Controller(req, res).api_Proxy()
  app.get '/flare/article/:ref' , (req, res)-> new Flare_Controller(req, res).show_Article()

  app.get '/flare/:page'        , (req, res)-> new Flare_Controller(req, res).render_Page()
  app.get '/flare'              , (req, res)->  res.redirect '/flare/main-app-view'


  #app.get '/flare/_dev'              , (req, res)->  res.redirect '/flare/_dev/all'
  #app.get '/flare/_dev/:area/:page'  , (req, res)->  res.send preCompiler.render_Jade_File '../TM_Flare/' + req.params.area + '/' + req.params.page + '.jade'
  #app.get '/flare/_dev/all'          , (req, res)->  res.send preCompiler.render_Jade_File '../TM_Flare/index.jade'
  #app.get '/flare/:page'             , (req, res)->  res.send preCompiler.render_Jade_File '../TM_Flare/' + req.params.page + '.jade'


  @

module.exports = Flare_Controller