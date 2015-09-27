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
                      '/'                     # there are two of these
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
                      '/angular/guest/pwd_reset/:username/:password'
                      '/browser'
                      '/browser-detect'
                      '/article/*'
                      '/search'
                      '/passwordReset/*'
                      '/misc/:page'
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
                      '/jade/Image/:name'
                      '/jade/a/:ref'
                      '/jade/article/:ref/:guid'
                      '/jade/article/:ref/:title'
                      '/jade/article/:ref'
                      '/jade/teamMentor/open/:guid'
                      '/teamMentor'
                      '/jade/articles'
                      '/jade/search'
                      '/jade/search/:text'
                      '/jade/show'
                      '/jade/show/:queryId'
                      '/jade/show/:queryId/:filters'
                      '/render/mixin/:file/:mixin'   # GET
                      '/render/mixin/:file/:mixin'   # POST (test blind spot due to same name as GET)
                      '/render/file/:file'
                      '/jade/guest/:page.html'
                      '/jade/guest/:page'
                      '/jade/passwordReset/:username/:token' # GET
                      '/jade/passwordReset/:username/:token' # POST
                      '/jade/help/index.html'
                      '/jade/help/:page*'
                      '/jade/help/article/:page*'
                      '/jade/index.html'
                      '/jade/user/login'
                      '/jade/user/logout'
                      '/_Customizations/SSO.aspx'
                      '/Aspx_Pages/SSO.aspx'
                      '/jade/user/main.html'
                      '/jade/user/pwd_reset'
                      '/jade/user/sign-up'
                      '/error'
                      '/poc*'
                      '/poc'
                      '/poc/:page'
                      '/jade/'
                      '/jade/json/recentarticles'
                      '/jade/json/toparticles'
                      '/json/user/login'
                      '/jade/json/article/:ref'
                      '/jade/json/user/pwd_reset'
                      '/json/user/currentuser'
                      '/jade/json/search/recentsearch'
                      '/json/user/signup'
                      '/json/user/logout'
                      '/jade/json/docs/library'
                      '/jade/json/docs/:page'
                      '/jade/json/gateways/library'
                      '/jade/json/search/gateways'
                      '/jade/json/passwordReset/:username/:token'
                      '/json/tm/config'
                      '/Image/:name'
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
                         .replace(':file','bbbbb')
                         .replace(':queryId','AAAA')
                         .replace(':filters','BBBB')
                         .replace(':guid','63deed1a-6df4-4e04-9f61-898f190e1fe1')
                         .replace('*','aaaaa')


      expectedStatus = 200;
      expectedStatus = 302 if ['','deploy', 'poc'                                 ].contains(path.split('/').second().lower())
      expectedStatus = 302 if ['/flare/','/flare/_dev','/flare/main-app-view',
                               '/user/logout','/pocaaaaa','/teamMentor'
                               '/angular/user/bbbbbaaaaa' ,
                               '/browser-detect', '/search', '/article/aaaaa'
                               '/passwordReset/aaaaa'].contains(path)

      expectedStatus = 403 if ['a','article','articles','show'                    ].contains(path.split('/')[2]?.lower())
      expectedStatus = 403 if ['/jade/user/main.html', '/jade/search', '/jade/search/:text'      ].contains(path)
      expectedStatus = 403 if ['/json/article/:ref'                               ].contains(path)
      expectedStatus = 302 if path is '/jade/article/:ref/63deed1a-6df4-4e04-9f61-898f190e1fe1'
      expectedStatus = 302 if path is '/teamMentor/open/63deed1a-6df4-4e04-9f61-898f190e1fe1'
      expectedStatus = 404 if ['/jade/aaaaa','/jade/Image/aaaaa'                            ].contains(path)
      expectedStatus = 500 if ['/error'                                           ].contains(path)

      postRequest = ['/jade/user/pwd_reset','/jade/user/sign-up' , '/jade/user/login',
                    '/flare/user/login','/json/user/login'
                     '/json/article/AAAAA'
                     '/json/user/pwd_reset', '/json/user/signup'
                     '/json/docs/AAAAA'                                           ].contains(path)

      testName = "[#{expectedStatus}] #{originalPath}" + (if(path != originalPath) then "  (#{path})" else  "")

      # this needs to be rewitten in order to take the more complex structure that we have now
      # for example we now need to tae into account the fact that there are some cases where the article(s) are shown


      return

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
