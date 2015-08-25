bodyParser      = require 'body-parser'
express         = require 'express'
request         = require 'superagent'
supertest       = require 'supertest'
cheerio         = require 'cheerio'
config          = require '../../src/config'

Express_Service = require '../../src/services/Express-Service'


describe '| routes | routes.test |', ()->

    @.timeout 7000
    express_Service = null
    app             = null
    tm_Server       = null
    global_Config   = null

    expectedPaths = [ '/'
                      '/angular/flare/:file'
                      '/angular/user/:file*'
                      '/angular/guest/:file'
                      '/angular/component/:file'
                      '/angular/jade/:file'
                      '/angular/api/auto-complete'
                      '/angular/jade/:area/:file'
                      '/angular/jade/:section/:area/:file'
                      '/angular/jade-html/:file'
                      '/angular/jade-html/:area/:file'
                      '/angular/jade-html/:section/:area/:file'
                      #'/api*?pretty'
                      #'/api*'                                # these paths are not being picked up
                      '/flare/:page'
                      '/flare/:area/:page'
                      '/flare/article/:ref'
                      '/flare/article/:ref/:title'
                      '/flare/help-index'
                      '/flare/help/:page*'
                      '/flare/navigate'
                      '/flare/navigate/:queryId'
                      '/flare/navigate/:queryId/:filters'
                      '/flare/user/login'
                      '/flare/user/search'
                      '/flare/'
                      '/Image/:name'
                      '/a/:ref'
                      '/article/:ref/:guid'
                      '/article/:ref/:title'
                      '/article/:ref'
                      '/teamMentor/open/:guid'
                      '/teamMentor'
                      '/articles'
                      '/search'
                      '/search/:text'
                      '/show'
                      '/show/:queryId'
                      '/show/:queryId/:filters'
                      '/render/mixin/:file/:mixin'   # GET
                      '/render/mixin/:file/:mixin'   # POST (test blind spot due to same name as GET)
                      '/render/file/:file'
                      '/guest/:page.html'
                      '/guest/:page'
                      '/passwordReset/:username/:token'
                      '/help/index.html'
                      '/help/:page*'
                      '/help/article/:page*'
                      '/misc/:page'
                      '/index.html'
                      '/user/login'
                      '/user/logout'
                      '/_Customizations/SSO.aspx'
                      '/Aspx_Pages/SSO.aspx'
                      '/user/main.html'
                      '/user/pwd_reset'
                      '/user/sign-up'
                      '/passwordReset/:username/:token'
                      '/error'
                      '/poc*'
                      '/poc'
                      '/poc/:page'
                      '/json/recentarticles'
                      '/json/toparticles'
                      '/json/user/login'
                      '/json/article/:ref'
                      '/json/user/pwd_reset'
                      '/json/user/currentuser'
                      '/json/search/recentsearch'
                      '/json/user/signup'
                      '/json/user/logout'
                      '/json/docs/library'
                      '/json/docs/:page'
                      '/*']
    before ()->
      username =''
      random_Port           = 10000.random().add(10000)
      app_35_Server         = new express().use(bodyParser.json())
      url_Mocked_3_5_Server = "http://localhost:#{random_Port}/webServices"
      app_35_Server.listen(random_Port)

      config.options.tm_design.webServices = url_Mocked_3_5_Server
      config.options.tm_design.jade_Compilation_Enabled = true

      options =
        logging_Enabled : false
        port            : 1024 + (20000).random()

      express_Service  = new Express_Service(options).setup().start()
      app              = express_Service.app

      tm_Server = supertest(app)

    after ()->
      app.server.close()
      config.restore()


    it 'Check expected paths', ()->
        paths = []
        routes = app._router.stack;

        for item in routes
          if (item.route)                                                  # add the routes added directly
            paths.push(item.route.path)
          else
            if item.handle.stack                                           # add the routes added via Route()
              root_Path = item.regexp.str().after('/^\\').before('\\/?(?') # hack to get the root path (which only seems to be avaiable as an regexp)
              for subitem in item.handle.stack
                if subitem.route
                  paths.push root_Path + subitem.route.path

        for path in paths
          expectedPaths.assert_Contains(path,"Path not found: #{path}")

        for path in expectedPaths
          paths.assert_Contains(path,"Path not found: #{path}")

        paths.length.assert_Is(expectedPaths.length)

    #dynamically create the tests
    runTest = (originalPath) ->
      path = originalPath.replace(':version','flare')
                         .replace(':area/:page','help/index')
                         .replace(':file/:mixin', 'globals/tm-support-email')
                         .replace(':page','default')
                         .replace(':name','aaaaa')
                         .replace(':queryId','AAAA')
                         .replace(':filters','BBBB')
                         .replace(':guid','63deed1a-6df4-4e04-9f61-898f190e1fe1')
                         .replace('*','aaaaa')


      expectedStatus = 200;
      expectedStatus = 302 if ['','deploy', 'poc'                                 ].contains(path.split('/').second().lower())
      expectedStatus = 302 if ['/flare/','/flare/_dev','/flare/main-app-view',
                               '/user/logout','/pocaaaaa','/teamMentor'].contains(path)

      expectedStatus = 403 if ['a','article','articles','show'                    ].contains(path.split('/').second().lower())
      expectedStatus = 403 if ['/user/main.html', '/search', '/search/:text'      ].contains(path)
      expectedStatus = 403 if ['/json/article/:ref'                               ].contains(path)
      expectedStatus = 302 if path is '/article/:ref/63deed1a-6df4-4e04-9f61-898f190e1fe1'
      expectedStatus = 302 if path is '/teamMentor/open/63deed1a-6df4-4e04-9f61-898f190e1fe1'
      expectedStatus = 404 if ['/aaaaa','/Image/aaaaa'                            ].contains(path)
      expectedStatus = 500 if ['/error'                                           ].contains(path)

      postRequest = ['/user/pwd_reset','/user/sign-up' , '/user/login',
                    '/flare/user/login','/json/user/login'
                     '/json/article/AAAAA'
                     '/json/user/pwd_reset', '/json/user/signup'
                     '/json/docs/AAAAA'                                           ].contains(path)

      testName = "[#{expectedStatus}] #{originalPath}" + (if(path != originalPath) then "  (#{path})" else  "")

      it testName, (done) ->

        checkResponse = (error,response) ->
          assert_Is_Null(error)
          response.text.assert_Is_String()
          done()
        if (postRequest)
          postData = {}
          postData ={username:"test",password:"somevalues",email:"someemail"}
          tm_Server.post(path).send(postData)
                              .expect(expectedStatus,checkResponse)
        else
          tm_Server.get(path)
                   .expect(expectedStatus,checkResponse)

    for route in expectedPaths
      runTest(route)
