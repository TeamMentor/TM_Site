express          = require 'express'
supertest        = require 'supertest'
Api_Controller   = require '../../src/controllers/Api-Controller'

describe.only '| controllers | Api-Controller |', ->

  it 'constructor',->

    using new Api_Controller(),->
      @.assert_Is_Object()

  describe 'using Express |', ->

    app = null

    before ->
      app  = new express()
      Api_Controller.register_Routes(app)

    it 'check route ', (done)->
      supertest(app)
      .get('/api/graph-db/predicates')
      .end (err, response, html)->
        log response.text
        done()