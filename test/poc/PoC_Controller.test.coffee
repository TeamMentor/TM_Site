PoC_Controller   = require '../../src/poc/PoC-Controller'
supertest        = require 'supertest'
express          = require 'express'
cheerio          = require 'cheerio'
path             = require 'path'
async            = require 'async'

describe '| poc | Controller-PoC.test |' ,->

  it 'constructor',->
    using new PoC_Controller() ,->
      @.dir_Poc_Pages.assert_Is "__poc"

  it 'folder_PoC_Pages', ->
    using new PoC_Controller() ,->
      @.folder_PoC_Pages().assert_Folder_Exists()
                          .assert_Contains '__poc'

  it 'check_Auth (anonymous)', (done)->
    res =
      redirect: (value)->
        value.assert_Is '/guest/404'
        done()

    new PoC_Controller().check_Auth(null,res,null)

  it 'check_Auth (user)', (done)->
    req = session: username : 'abc'
    new PoC_Controller().check_Auth(req, null, done)

  it 'jade_Files', (done)->
    using new PoC_Controller() ,->
      files = @.jade_Files().assert_Not_Empty()
      @.folder_PoC_Pages().files_Recursive().assert_Contains files
      done()

  it 'map_Files_As_Pages', (done)->
    using new PoC_Controller() ,->
      pages      = @.map_Files_As_Pages()
      mappings   = {}
      mappings[page.name]=page.link for page in pages
      for file in @.jade_Files()
        fileName = file.file_Name_Without_Extension()
        mappings[fileName].assert_Is "/poc/#{fileName}"
      mappings['Articles'].assert_Is '/articles'
      done()

  it 'show_Index', (done)->
    req = {}
    res =
      status: (value)->
        value.assert_Is 200
        @
      send: (html)->
        html.assert_Contains ['Article' , 'poc-pages', 'top-articles']
        done()

    new PoC_Controller().show_Index(req,res)

  it 'show_Page (good link)', (done)->
    @.timeout 5000
    express_Service =
      session_Service:
          user_Data: (session, callback) -> callback []
    using new PoC_Controller({ express_Service: express_Service}), ->

      req = params : page : @.map_Files_As_Pages().last().name
      res =
        status: (value)->
          value.assert_Is 200
          @
        send: (html)->
          html.assert_Is_String()
          done()

      @.show_Page(req,res)

  it 'show_Page (bad link) , render_Jade', (done)->
    using new PoC_Controller(), ->

      req = params : page : 'aaaaabbbb'
      res =
        redirect: (target)->
          target.assert_Is '/guest/404'
          done()

      @.show_Page(req,res)

  it 'register_Routes', ()->
    routes     = {}
    auth_Check = null
    express_Service =
      app:
        get: (path,target)-> routes[path] = target

    using new PoC_Controller({ express_Service: express_Service}).register_Routes() ,->
      routes.assert_Is
        '/poc*'                     : @.check_Auth
        '/poc'                      : @.show_Index
        '/poc/:page'                : @.show_Page


  it 'view_Model_For_Page', (done)->
    @.timeout 5000
    express_Service =
      session_Service:
        top_Articles: (callback        ) -> callback []
        top_Searches: (callback        ) -> callback []
        user_Data   : (session,callback) -> callback []

    using new PoC_Controller({ express_Service: express_Service}), ->

      test_Page = (page_Name, next)=>

        req = params : page : page_Name

        res =
          status: (value)->
            value.assert_Is 200
            @
          send: (html)->
            html.assert_Is_String()
            next()

        @.show_Page(req,res)

      page_Names = (item.name for item  in @.map_Files_As_Pages())
      page_Names.shift()
      async.eachSeries page_Names, test_Page, done

  describe 'using Express |', ->
    it 'check Auth redirect', (done)->
      app = new express()
      express_Service = app : app
      new PoC_Controller({express_Service:express_Service}).register_Routes()
      supertest(app)
        .get('/poc')
        .end (err, response, html)->
          response.text.assert_Is 'Moved Temporarily. Redirecting to /guest/404'
          done()
