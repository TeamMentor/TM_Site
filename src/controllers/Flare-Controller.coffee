request            = null
Jade_Service       = null
Article_Controller = null
Login_Controller   = null

class Flare_Controller

  dependencies: ->
    request            = require 'request'
    Jade_Service       = require '../services/Jade-Service'
    Article_Controller = require './Article-Controller'
    Login_Controller   = require './Login-Controller'

  constructor: ()->
    @.dependencies()
    @.graphDb_Port       = global.config?.tm_graph?.port
    @.graphDb_Server     = "http://localhost:#{@.graphDb_Port}"


  render_Page: (req,res, next, params)=>
    path = '../TM_Flare/' + req.params.page + '.jade'
    using new Jade_Service(), ->
      res.send @.render_Jade_File path, params

  show_Article: (req,res)=>
    using new Article_Controller(req,res), ->
      @.jade_Article = '../TM_Flare/article-new-window-view.jade'
      @.article()

  user_Login: (req, res)=>
    using new Login_Controller(req,res), ->
      @.jade_LoginPage             = '../TM_Flare/get-started.jade'
      @.jade_LoginPage_Unavailable = '../TM_Flare/get-started.jade' #'../TM_Flare/login-cant-connect.jade'
      @.jade_GuestPage_403         = '../TM_Flare/get-started.jade' #'../TM_Flare/403.jade'
      @.page_MainPage_user         = '/flare/main-app-view'
      @.page_MainPage_no_user      = '/flare/index'
      @.loginUser()


#../TM_Flare/article-new-window-view.jade



Flare_Controller.register_Routes =  (app)=>
  flare_Controller = new Flare_Controller()
  app.get  '/flare/article/:ref' , flare_Controller.show_Article
  app.post '/flare/user/login'   , flare_Controller.user_Login
  app.get  '/flare/:page'        , flare_Controller.render_Page
  app.get  '/flare'              , (req, res)-> res.redirect '/flare/index'


  #app.get '/flare/_dev'              , (req, res)->  res.redirect '/flare/_dev/all'
  #app.get '/flare/_dev/:area/:page'  , (req, res)->  res.send preCompiler.render_Jade_File '../TM_Flare/' + req.params.area + '/' + req.params.page + '.jade'
  #app.get '/flare/_dev/all'          , (req, res)->  res.send preCompiler.render_Jade_File '../TM_Flare/index.jade'
  #app.get '/flare/:page'             , (req, res)->  res.send preCompiler.render_Jade_File '../TM_Flare/' + req.params.page + '.jade'


  @

module.exports = Flare_Controller