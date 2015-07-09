Router   = null
express  = null

if process.cwd().contains('.dist')
  root_Folder = process.cwd().path_Combine '../../../'
else
  root_Folder = process.cwd().path_Combine '../../'

autoComplete_Data = null

class Angular_Controller

  dependencies: ->
    express      = require 'express'
    {Router}     = require 'express'

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
      path_Queries = 'http://localhost:12346/search/query_titles'
      path_Queries.json_GET (data_Queries)=>
        path_Articles.json_GET (data_Articles)=>
          autoComplete_Data = data_Queries.sort().concat data_Articles
          #for item in autoComplete_Data
          #  console.log item
          #console.log "THERE ARE #{data_Queries.size()} #{data_Articles.size()} #{autoComplete_Data.size()}"
          #console.log autoComplete_Data
          @.send_Search_Auto_Complete term, res


  get_Compiled_Jade: (req,res)=>
    jade = require('jade');
    file = req.params.file
    area = req.params.area
    path = root_Folder.path_Combine "/code/TM_Jade/#{area}/#{file}.jade"
    if path.file_Not_Exists()
      return res.json { error: 'jade file not found' }

    options = {name : "jade_#{file}" }
    jsFunctionString = jade.compileFileClient(path, options);
    res.send jsFunctionString

  routes: ()=>
    router = new Router()
    router.use express['static'](@.path_To_Static);
    router.get '/api/auto-complete', @.get_Search_Auto_Complete
    router.get '/jade/:area/:file', @.get_Compiled_Jade
    return router

module.exports = Angular_Controller
