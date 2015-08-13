require 'fluentnode'

express            = require 'express'
Angular_Controller = require '../../src/controllers/Angular-Controller'
supertest          = require 'supertest'

describe '| controllers | Angular-Controller |', ->

  it 'constructor',->
    using new Angular_Controller(), ->
      @.path_To_Static.assert_Is_String()

  it 'routes', ->
    using new Angular_Controller(), ->
      @.routes().stack.size().assert_Is 12

  describe '| Using express',->

    tm_Site = {}

    set_Server = (site)->
      site.port       = 10000.random().add(10000)
      site.server_Url = "http://localhost:#{site.port}"
      site.app        = new express()
      site.server     = site.app.listen(site.port)
      site.get        = (path, callback)-> site.server_Url.add(path).GET callback

    before ->
      set_Server tm_Site
      tm_Site.app.use new Angular_Controller().routes()

    after ->
      tm_Site.server.close()


    it 'test static routes', (done)->
      tm_Site.get '/js/lib.js', (data)->
        data.size().assert_Bigger_Than 150000
        done()
