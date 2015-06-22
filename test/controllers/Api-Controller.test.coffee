express          = require 'express'
supertest        = require 'supertest'
API_Controller   = require '../../src/controllers/Api-Controller'

describe.only '| controllers | Api-Controller |', ->

  it 'constructor',->

    using new API_Controller(),->
      @.assert_Is_Object()

  describe 'using Express |', ->

    app            = null
    api_Controller = null

    before ()->
      app  = new express()
      api_Controller = new API_Controller() #.register_Routes(app)
      app.use api_Controller.routes()

      app.get '/*', (req,res,next)->
        log 'in login .....'
        req.session = {}
        req.session.username = 'test'
        log 'in login'
        next()


    it 'check_Auth', (done)->
      request = supertest(app)
      request.get('/api/graph-db/predicates')
             .end (err, response, html)->
                log API_Controller.LOGIN_FAIL_MESSAGE
                log response.text

                done()

    xit 'check route ', (done)->
      request = supertest(app)
      request.get('/login').end ->

        request.get('/api/graph-db/predicates')
               .end (err, response, html)->
                log response.text
                done()