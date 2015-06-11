Jade_Service = null

register_Routes =   (express_Service)->

  Jade_Service = require('../services/Jade-Service')
  app          = express_Service.app

  preCompiler =
    render_Jade_File: (path)->
      return new Jade_Service().render_Jade_File(path)

  app.get '/flare/_dev'              , (req, res)->  res.redirect '/flare/_dev/all'
  app.get '/flare'                   , (req, res)->  res.redirect '/flare/main-app-view'

  app.get '/flare/_dev/:area/:page'  , (req, res)->  res.send preCompiler.render_Jade_File '../TM_Flare/' + req.params.area + '/' + req.params.page + '.jade'
  app.get '/flare/_dev/all'          , (req, res)->  res.send preCompiler.render_Jade_File '../TM_Flare/index.jade'
  app.get '/flare/:page'             , (req, res)->  res.send preCompiler.render_Jade_File '../TM_Flare/' + req.params.page + '.jade'


module.exports = register_Routes