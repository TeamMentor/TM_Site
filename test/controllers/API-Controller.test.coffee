express          = require 'express'
supertest        = require 'supertest'
API_Controller   = require '../../src/controllers/Api-Controller'

describe '| controllers | Api-Controller |', ->

  app            = null
  api_Controller = null

  tm_Site        = {}
  db_Site        = {}
  auto_Login     = true

  set_Server = (site)->
    site.port       = 10000.random().add(10000)
    site.server_Url = "http://localhost:#{site.port}"
    site.app        = new express()
    site.server     = site.app.listen(site.port)

    site.get        = (path, callback)-> site.server_Url.add(path).GET_Json callback

  before ()->
    set_Server tm_Site
    set_Server db_Site

    api_Controller = new API_Controller();

    api_Controller.graphDb_Server = db_Site.server_Url

    tm_Site.app.get '*', (req,res,next)->
      if auto_Login
        req.session = username : 'test'
      next()

    db_Site.app.get '/*', (req,res,next)->
      res.send { source :'db_Site' , url:req.url }

    tm_Site.app.use api_Controller.routes()

  after ->
    tm_Site.server.close()
    db_Site.server.close()

  it 'constructor',->

    using new API_Controller(),->
      @.assert_Is_Object()

  it 'api_Proxy', (done)->
    tm_Site.get '/api/graph-db/predicates', (json)->
      json.assert_Url is 'graph-db/predicates'
      done()

  it 'check_Auth', (done)->
    auto_Login = false
    tm_Site.get '/api/aaa/bbb', (json)->
      json.assert_Is API_Controller.LOGIN_FAIL_MESSAGE
      auto_Login = true
      done()

