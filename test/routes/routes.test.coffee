bodyParser      = require 'body-parser'
express         = require 'express'
request         = require 'superagent'
supertest       = require 'supertest'
cheerio         = require 'cheerio'

Express_Service = require '../../src/services/Express-Service'


describe '| routes | routes.test |', ()->

    @.timeout 7000
    express_Service = null
    app             = null
    tm_Server       = null
    global_Config   = null

    expectedPaths = [ '/'
                      '/angular/api/auto-complete'
                      '/angular/jade/:area/:file'
                      '/flare/:page'
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
                      '/poc/filters:page'
                      '/poc/filters:page/:filters'
                      '/poc/:page'
                      '/*']
    before ()->
      username =''
      random_Port           = 10000.random().add(10000)
      app_35_Server         = new express().use(bodyParser.json())
      url_Mocked_3_5_Server = "http://localhost:#{random_Port}/webServices"
      app_35_Server.post '/webServices/SendPasswordReminder', (req,res)->res.status(201).send {}      # status(200) would trigger a redirect
      app_35_Server.post '/webServices/Login_Response'      ,
        (req,res)->
          username = req.body.username
          logged_In = if req.body.username is 'user' or 'expired' then 0 else 1
          res.status(200).send { d: { Login_Status : logged_In,Token:'00000000' } }

      app_35_Server.post '/webServices/Current_User'      ,
        (req,res)->
          PasswordExpired = if username is 'expired' then true else false
          res.status(200).send {d:{"UserId":1982362528,"CSRF_Token":"115362661","PasswordExpired":PasswordExpired}}

      app_35_Server.post '/webServices/GetCurrentUserPasswordExpiryUrl'      ,
        (req,res)->
          res.status(200).send {"d":"/passwordReset/user/00000000-0000-0000-0000-000000000000"}

      app_35_Server.use (req,res,next)-> log('------' + req.url); res.send null
      app_35_Server.listen(random_Port)

      global_Config = global.config
      global.config.tm_design.webServices = url_Mocked_3_5_Server
      global.config.tm_design.jade_Compilation_Enabled = true

      options =
        logging_Enabled : false
        port            : 1024 + (20000).random()

      express_Service  = new Express_Service(options).setup().start()
      app              = express_Service.app

      tm_Server = supertest(app)

    after ()->
      app.server.close()
      global.config = global_Config
      #express_Service.logging_Service.restore_Console()


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
                         .replace('*','aaaaa')


      expectedStatus = 200;
      expectedStatus = 302 if ['','deploy', 'poc'                                 ].contains(path.split('/').second().lower())
      expectedStatus = 302 if ['/flare/','/flare/_dev','/flare/main-app-view',
                               '/user/logout','/pocaaaaa','/teamMentor','/user/login','/flare/user/login'           ].contains(path)

      expectedStatus = 403 if ['a','article','articles','show'                    ].contains(path.split('/').second().lower())
      expectedStatus = 403 if ['/user/main.html', '/search', '/search/:text'      ].contains(path)
      expectedStatus = 403 if path is '/teamMentor/open/:guid'
      expectedStatus = 404 if ['/aaaaa','/Image/aaaaa'                            ].contains(path)
      expectedStatus = 500 if ['/error'                                           ].contains(path)

      postRequest = ['/user/pwd_reset','/user/sign-up' , '/user/login',
                    '/flare/user/login'                                           ].contains(path)

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

    it 'Issue_679_Validate authentication status on error page', (done)->
      agent = request.agent()
      baseUrl = 'http://localhost:' + app.port

      loggedInText = ['<span title="Logout" class="icon-Logout">']
      loggedOutText = ['<li><a id="nav-login" href="/guest/login.html">Login</a></li>']

      postData = {username:'user', password:'a'}
      userLogin = (agent, postData, next)-> agent.post(baseUrl + '/user/login').send(postData).end (err,res)->
        assert_Is_Null(err)
        next()
      userLogout = (next)-> agent.get(baseUrl + '/user/logout').end (err,res)->
        res.status.assert_Is(200)
        next()

      get404 = (agent, text, next)-> agent.get(baseUrl + '/foo').end (err,res)->
        res.status.assert_Is(404)
        res.text.assert_Contains(text)
        next()
      get500 = (agent, text, next)-> agent.get(baseUrl + '/error?{#foo}').end (err,res)->
        res.status.assert_Is(500)
        res.text.assert_Contains(text)
        next()

      userLogin agent,postData, ->
        get404 agent,loggedInText, ->
          get500 agent,loggedInText, ->
            userLogout ->
              get404 agent, loggedOutText, ->
                get500 agent, loggedOutText, ->
                  done()

    it 'Issue_894_PasswordReset - User should be challenged to change his/her password if it was expired', (done)->
      agent = request.agent()
      baseUrl = 'http://localhost:' + app.port

      postData = {username:'expired', password:'a'}
      userLogin = (agent, postData, next)-> agent.post(baseUrl + '/user/login').send(postData).end (err,res)->
        $ = cheerio.load(res.text)
        $('h4').html().assert_Is 'Reset your password'
        $('p') .html().assert_Is 'Your password should be at least 8 characters long. It should have at least one of each of the following: uppercase and lowercase letters, number and special character.'
        next()

      userLogout = (next)-> agent.get(baseUrl + '/user/logout').end (err,res)->
        res.status.assert_Is(200)
        next()
      userLogin agent,postData, ->
        userLogout ->
          done()
