bodyParser      = require 'body-parser'
express         = require 'express'
request         = require 'superagent'
supertest       = require 'supertest'
cheerio         = require 'cheerio'
config          = require '../../src/config'

Express_Service = require '../../src/services/Express-Service'

describe '| routes | routes.checks |', ()->

  app             = null

  beforeEach ()->
    username =''
    random_Port           = 10000.random().add(10000)

    app_35_Server         = new express().use(bodyParser.json())
    url_Mocked_3_5_Server = "http://localhost:#{random_Port}"

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

    #app_35_Server.use (req,res,next)->
    #  console.log req.url
    #  log('------' + req.url)
    #  res.status(500).send 'WebService route not mapped'

    app_35_Server.listen(random_Port)

    using config.options,->
      @.tm_design.tm_35_Server             = url_Mocked_3_5_Server
      @.tm_design.webServices              = '/webServices'
      @.tm_design.jade_Compilation_Enabled = true

    express_Options =
      logging_Enabled : false
      port            : 1024 + (20000).random()

    express_Service  = new Express_Service(express_Options).setup().start()
    app              = express_Service.app

    tm_Server = supertest(app)

  afterEach ->
    config.restore()

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
