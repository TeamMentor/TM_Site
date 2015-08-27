Jade_Service = null

content_cache = {};

class Misc_Controller

  dependencies: ->
    Jade_Service = require('../services/Jade-Service')

  constructor: (req, res)->
    @.dependencies()
    @.req       = req || {}
    @.res       = res || {}
    @.config    = require '../config'

  json_Mode: ()=>
    @.render_Page = (page, data)=>
      data.page = page
      @.res.json data
    @.res.redirect = (page)=>
      data =
        page     : page
        viewModel: {}
        result   : 'OK'
      @.res.json data
    @

  show_Misc_Page: ()=>
    jade_Page  = 'misc/' + @.req.params.page + '.jade'
    view_Model = loggedIn: @.user_Logged_In()
    html = new Jade_Service().render_Jade_File(jade_Page, view_Model)
    @.res.status(200)
         .send(html)

  user_Logged_In: ()=>
    @req.session?.username isnt undefined

  tmConfig: ()=>
    config =  {
                supportEmail        : @.config.options.tm_design.supportEmail,
                githubUrl           : @.config.options.tm_design.supportEmail,
                githubContentUrl    : @.config.options.tm_design.githubContentUrl,
                allowedEmailDomains : @.config.options.tm_design.allowedEmailDomains
              }
    @.res.json config

Misc_Controller.register_Routes =  (app, expressService) ->
  checkAuth       =  (req,res,next) ->
    expressService.checkAuth(req, res, next)

  misController = (method_Name) ->
    return (req, res,next) ->
      new Misc_Controller(req, res, next,expressService)[method_Name]()

  app.get '/misc/:page'     , (req, res)-> new Misc_Controller(req, res).show_Misc_Page()
  app.get '/json/tm/config' , checkAuth, misController('tmConfig')



module.exports = Misc_Controller