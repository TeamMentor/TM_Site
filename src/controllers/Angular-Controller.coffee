Router   = null
express  = null

if process.cwd().contains('.dist')
  root_Folder = process.cwd().path_Combine '../../../'
else
  root_Folder = process.cwd().path_Combine '../../'

article_Titles = null

class Angular_Controller

  dependencies: ->
    express      = require 'express'
    {Router}     = require 'express'

  constructor: ()->
    @.dependencies()
    @.path_To_Static = root_Folder.path_Combine 'code/TM_Angular/build'
    log @.path_To_Static
    log @.path_To_Static.folder_Exists()

  send_Search_Auto_Complete: (term, res)->
    console.time 'search'
    matches = {}
    for match in article_Titles when match.title.lower().contains(term.lower())
      matches[match.title] = match.id
      if (matches.keys().size() > 15)
        break
    log matches.keys().size()
    logger.restore_Console()
    console.timeEnd('search')

    res.json matches

  get_Search_Auto_Complete: (req,res)=>
    term = req.query?.term || ''
    if article_Titles
      @.send_Search_Auto_Complete term, res
    else
      path = 'http://localhost:12346/search/article_titles'
      path.json_GET (data)=>
        article_Titles = data
        @.send_Search_Auto_Complete term, res





  routes: ()=>
    router = new Router()
    router.use express['static'](@.path_To_Static);
    router.get '/api/auto-complete', @.get_Search_Auto_Complete
    return router

module.exports = Angular_Controller
