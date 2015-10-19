Router        = null
express       = null
Jade_Service  = null

if process.cwd().contains('wallaby')
  root_Folder = process.cwd()
else
  root_Folder = process.cwd().path_Combine '../../'

autoComplete_Data = null
config            = null
class Angular_Controller

  dependencies: ->
    express       = require 'express'
    {Router}      = require 'express'
    Jade_Service  = require '../services/Jade-Service'
    config        = require '../config'

  constructor: ()->
    @.dependencies()
    @.port_TM_Graph  = config?.options?.tm_graph?.port
    @.path_To_Static = root_Folder.path_Combine 'code/TM_Angular/build'
    @.url_TM_Graph   = "http://localhost:#{@.port_TM_Graph}"
    @.url_Articles   = "#{@.url_TM_Graph}/search/article_titles"
    @.url_Queries    = "#{@.url_TM_Graph}/search/query_titles"
    @.url_Words      = "#{@.url_TM_Graph}/search/all_words"
    @.guest_Whitelist  = ["home","about","features","docs","sign_up","login","error","logout","terms-and-conditions"]

    @.redirectPage   = '/angular/guest/home'
    @.loginPage      = '/angular/guest/login'

  send_Search_Auto_Complete: (term, res)->
    matches = {}
    for match in autoComplete_Data when match.title.lower().contains(term.lower())
      matches[match.title] = match.id
      if (matches.keys().size() > 15)
        break
    res.json matches

  get_Search_Auto_Complete: (req,res)=>
    term = req.query?.term || ''
    if autoComplete_Data
      @.send_Search_Auto_Complete term, res
    else
      @.url_Queries.json_GET (data_Queries)=>
        @.url_Articles.json_GET (data_Articles)=>
          @.url_Words.json_GET (data_Words)=>
            if data_Queries.sort
              autoComplete_Data = data_Queries.concat(data_Articles)
            else
              autoComplete_Data =[]
            if data_Words.sort
              for word in data_Words
                autoComplete_Data.push { title: word, id: "word-#{word}" }

            autoComplete_Data.sort()
            @.send_Search_Auto_Complete term, res

  get_Static_Html: (req,res)=>
    file = req.params.file
    if file isnt 'guest'
      req.params.file = 'page-user'
    else
      req.params.file = 'page-guest'

    req.params.area = '_layouts'

    @.get_Rendered_Jade req,res

  get_Static_Html_User: (req,res)=>
    req.params.file = 'page-user'
    req.params.area = '_layouts'
    @.get_Rendered_Jade req,res

  get_Static_Html_Guest: (req,res)=>
    #picking the route which should match with the whitelist
    view       = req.url?.split('/')?.last()

    if view? && view in @.guest_Whitelist || req.url.contains 'guest/pwd_reset'
      req.params.file = 'page-guest'
      req.params.area = '_layouts'

      @.get_Rendered_Jade req,res
    else
      if req?.session?.username
        return res.redirect '/angular/user/error'
      else
        return res.redirect '/angular/guest/error'


  get_Static_Html_Component:  (req,res)=>
    req.params.file = 'page-component'
    req.params.area = '_layouts'
    @.get_Rendered_Jade req,res

  resolve_Jade_file: (file,area, section)=>     # this needs a rewrite
    if (section)
      root_Folder.path_Combine "/code/TM_Flare/#{section}/#{area}/#{file}.jade"
    else if (area)
      root_Folder.path_Combine "/code/TM_Flare/#{area}/#{file}.jade"
    else
      root_Folder.path_Combine "/code/TM_Flare/#{file}.jade"

  get_Index_Page : (req,res)=>               #Route /user/home should not exist,so we redirect to index if any user hits this pattern.
    res.redirect '/angular/user/index'

  get_Compiled_Jade: (req,res)=>
    jade    = require('jade');
    file    = req.params.file
    area    = req.params.area
    section = req.params.section
    path = @.resolve_Jade_file(file, area, section)
    if path.file_Not_Exists()
      return res.json { error: 'jade file not found' }
    options = {name : "jade_#{file}" }
    jsFunctionString = jade.compileFileClient(path, options);
    res.send jsFunctionString

  get_Rendered_Jade: (req,res)=>
    file    = req.params.file
    area    = req.params.area
    section = req.params.section
    path = @.resolve_Jade_file(file, area, section)
    using new Jade_Service(), ->
      res.send @.render_Jade_File path, {}

  check_Auth: (req,res,next)=>
    if req?.session?.username
      redirectUrl = req?.session?.angularRedirectUrl    #Pulling session data
      if (redirectUrl? && redirectUrl.is_Local_Url())   #avoiding open redirects
        delete req?.session?.angularRedirectUrl         #deleting value from session
        return res?.redirect(redirectUrl)               #redirecting
      else
       return next()
    else
      if (req?.url?.starts_With('/user/'))
        req?.session?.angularRedirectUrl = "/angular" +req.url  #Setting up redirect URL
        return res?.redirect(@.loginPage)
      else
        return res?.redirect(@.redirectPage)

  routes: ()=>
    router = new Router()
    router.get '/flare/:file'                         , @.get_Static_Html
    router.get '/user/home'            ,@.check_Auth  , @.get_Index_Page
    router.get '/user/:file*'          ,@.check_Auth  , @.get_Static_Html_User
    router.get '/guest/:file'                         , @.get_Static_Html_Guest
    router.get '/guest/pwd_reset/:username/:password' , @.get_Static_Html_Guest
    router.get '/component/:file'                     , @.get_Static_Html_Component
    router.get '/api/auto-complete'                   , @.get_Search_Auto_Complete

    router.get '/jade/:file'                          , @.get_Compiled_Jade
    router.get '/jade/:area/:file'                    , @.get_Compiled_Jade
    router.get '/jade/:section/:area/:file'           , @.get_Compiled_Jade
    router.get '/jade-html/:file'                     , @.get_Rendered_Jade
    router.get '/jade-html/:area/:file'               , @.get_Rendered_Jade
    router.get '/jade-html/:section/:area/:file'      , @.get_Rendered_Jade

    router.use express['static'](@.path_To_Static);

    return router

module.exports = Angular_Controller
