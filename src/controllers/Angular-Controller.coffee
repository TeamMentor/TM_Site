Router        = null
express       = null
Jade_Service  = null

if process.cwd().contains('.dist')
  root_Folder = process.cwd().path_Combine '../../../'
else
  root_Folder = process.cwd().path_Combine '../../'

autoComplete_Data = null

class Angular_Controller

  dependencies: ->
    express       = require 'express'
    {Router}      = require 'express'
    Jade_Service  = require '../services/Jade-Service'

  constructor: ()->
    @.dependencies()
    @.path_To_Static = root_Folder.path_Combine 'code/TM_Angular/build'

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
      path_Articles = 'http://localhost:12346/search/article_titles'
      path_Queries  = 'http://localhost:12346/search/query_titles'
      path_Queries.json_GET (data_Queries)=>
        path_Articles.json_GET (data_Articles)=>
          autoComplete_Data = data_Queries.sort().concat data_Articles
          #for item in autoComplete_Data
          #  console.log item
          #console.log "THERE ARE #{data_Queries.size()} #{data_Articles.size()} #{autoComplete_Data.size()}"
          #console.log autoComplete_Data
          @.send_Search_Auto_Complete term, res

  get_Static_Html: (req,res)=>
    #path = "#{@.path_To_Static}/html/index.html";
    #res.sendFile path
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
    req.params.file = 'page-guest'
    req.params.area = '_layouts'
    @.get_Rendered_Jade req,res


  resolve_Jade_file: (file,area)=>
    return if (area)
      root_Folder.path_Combine "/code/TM_Flare/#{area}/#{file}.jade"
    else
      root_Folder.path_Combine "/code/TM_Flare/#{file}.jade"


  get_Compiled_Jade: (req,res)=>
    jade = require('jade');
    file = req.params.file
    area = req.params.area
    path = @.resolve_Jade_file(file, area)
    if path.file_Not_Exists()
      return res.json { error: 'jade file not found' }
    options = {name : "jade_#{file}" }
    jsFunctionString = jade.compileFileClient(path, options);
    res.send jsFunctionString

  get_Rendered_Jade: (req,res)=>
    file = req.params.file
    area = req.params.area
    path = @.resolve_Jade_file(file, area)

    using new Jade_Service(), ->
      res.send @.render_Jade_File path, {}

  routes: ()=>
    router = new Router()
    router.use express['static'](@.path_To_Static);
    router.get '/flare/:file'          , @.get_Static_Html
    router.get '/user/:file*'          , @.get_Static_Html_User
    router.get '/guest/:file'          , @.get_Static_Html_Guest
    router.get '/api/auto-complete'    , @.get_Search_Auto_Complete
    router.get '/jade/:file'           , @.get_Compiled_Jade
    router.get '/jade/:area/:file'     , @.get_Compiled_Jade
    router.get '/jade-html/:file'      , @.get_Rendered_Jade
    router.get '/jade-html/:area/:file', @.get_Rendered_Jade
    return router

module.exports = Angular_Controller
