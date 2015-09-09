Jade_Service       = null
Help_Controller    = null
class Jade_Controller
  constructor: (req, res)->
    Jade_Service     = require('../services/Jade-Service')
    Help_Controller  = require './Help-Controller'
    @.req            = req;
    @.res            = res;
    @.jade_Service   = new Jade_Service();


  renderMixin: (viewModel)=>
    if viewModel and viewModel.viewModel
      viewModel = JSON.parse viewModel.viewModel
    file  = @req.params.file
    mixin = @req.params.mixin
    html  = @.jade_Service.render_Mixin(file, mixin,viewModel || {})
    @.res.send(html)

  renderMixin_GET: ()=>
    @renderMixin @.req.query

  renderMixin_POST: ()=>
    @renderMixin @.req.body

  renderFile: (viewModel)=>
    file_Raw  =  @.req.params.file.to_Safe_String().replace(/_/g,'/')
    file      = "#{file_Raw}.jade"
    html      =  @.jade_Service.render_Jade_File(file, viewModel || {})
    @.res.send(html)

  renderFile_GET: ()=>
    @.renderFile @.req.query

  show_Image: ()=>
    using new Help_Controller(@.req,@.res),->
      @.show_Image()

Jade_Controller.register_Routes =  (app)=>

  app.get  '/render/mixin/:file/:mixin' ,    (req, res)=> new Jade_Controller(req, res, app.config).renderMixin_GET()
  app.post '/render/mixin/:file/:mixin' ,    (req, res)=> new Jade_Controller(req, res, app.config).renderMixin_POST()
  app.get  '/render/file/:file'         ,    (req, res)=> new Jade_Controller(req, res, app.config).renderFile_GET()
  app.get  '/Image/:name'               ,    (req, res)=> new Jade_Controller(req, res, app.config).show_Image()


module.exports = Jade_Controller