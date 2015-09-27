express                 = require 'express'
bodyParser              = require('body-parser')
Login_Controller        = require('../../src/controllers/Login-Controller')
User_Sign_Up_Controller = require('../../src/controllers/User-Sign-Up-Controller')
config                  = require '../../src/config'

describe '| controllers | User-Sign-Up-Controller', ->

  signUp_fail                     = "guest/sign-up-Fail.jade"
  signUpPage_Unavailable          = 'guest/sign-up-cant-connect.jade'
  #signUp_Ok                       = '/guest/sign-up-OK.html'
  mainPage_user                   = '/jade/show'
  text_Short_Pwd                  = 'Password must be 8 to 256 character long'
  #text_Bad_Pwd                    = 'Password must contain a non-letter and a non-number character'
  text_password_NoMatch           =  'Passwords don\'t match'
  text_username_Required          = 'Username is a required field.'
  text_password_Required          = 'Password is a required field.'
  text_confirmpassword_Required   = 'Confirm password is a required field.'
  text_email_Required             = 'Email is a required field.'
  text_firstName_Required         = 'First Name is a required field.'
  text_lastName_Required          = 'Last Name is a required field.'
  text_country_Required           = 'Country is a required field.'
  #text_An_Error                   = 'An error occurred'

  random_Port     = 10000.random().add(10000)

  server                          = null
  url_WebServices                 = null
  on_CreateUser_Response          = null
  users                           = {}
  passwordStrengthRegularExpression =///(
        #(?=.*\d)            # at least 1 digit
        #(?=.*[A-Z])         # at least 1 upper case letter
        (?=.*[a-z])         # at least 1 lower case letter
        (?=.*\W)            # at least 1 special character
        .                   # match any with previous validations
        {8,256}             # 8 to 256 characters
       )///

  add_TM_WebServices_Routes = (app)=>
    app.post '/Aspx_Pages/TM_WebServices.asmx/Login_Response', (req,res)=>
      username = req.body.username
      password = req.body.password
      if users[username] is password and password
        res.send { d: { Login_Status: 0}  }

    app.post '/Aspx_Pages/TM_WebServices.asmx/CreateUser_Response', (req,res)=>
      if on_CreateUser_Response
        return on_CreateUser_Response(req,res)

      username = req.body.newUser.username
      password = req.body.newUser.password
      email    = req.body.newUser.email
      if username and password and email

        if not (password.size().in_Between(7, 257))
          res.send { d: { Signup_Status: 1 , Validation_Results: [], Simple_Error_Message: text_Short_Pwd } }
          return

        if password.match(passwordStrengthRegularExpression)
          users[username] = password
          res.send { d: { Signup_Status: 0 , Validation_Results: [], Simple_Error_Message: 'sign-up ok' } }
     #     return

     #   res.send { d: { Signup_Status: 1 , Validation_Results: [{Message: text_Bad_Pwd }], Simple_Error_Message: '' } }
     # else
     #   res.send { d: { Signup_Status: 1, Validation_Results: [] } }

  before (done)->
    url_WebServices = "http://localhost:#{random_Port}/Aspx_Pages/TM_WebServices.asmx"
    app             = new express().use(bodyParser.json())
    add_TM_WebServices_Routes(app)
    server          = app.listen(random_Port)

    url_WebServices.GET (html)->
      html.assert_Is 'Cannot GET /Aspx_Pages/TM_WebServices.asmx\n'
      done()

  beforeEach ()->
    config.options.tm_design.tm_35_Server = "http://localhost:#{random_Port}"

  afterEach ->
    config.restore()

  after ->
    server.close()

  invoke_UserSignUp = (username, password,confirmpassword, email, firstname, lastname, country,expected_Target, expected_ErrorMessage, callback)->
    req =
      session: {}
      url    : '/passwordReset/temp/00000000-0000-0000-0000-000000000000'
      body   : { username: username , password: password,'confirm-password':confirmpassword , email: email,firstname:firstname, lastname:lastname,country:country}

    res =
      redirect: (target)->
        target.assert_Is(expected_Target)
        callback()
    render_Page = (jade_Page, params) ->
        params.viewModel.errorMessage.assert_Is expected_ErrorMessage
        jade_Page.assert_Is(expected_Target)
        callback()

    mockedLogin = new Login_Controller(req,res)
    mockedLogin.webServices = url_WebServices
    using new User_Sign_Up_Controller(req, res), ->
      @.render_Page = render_Page
      @.webServices = url_WebServices
      @.login= mockedLogin
      @.userSignUp()


  invoke_LoginUser = (username, password, expected_Target, callback)->
    req =
      session: {}
      url    : '/passwordReset/temp/00000000-0000-0000-0000-000000000000'
      body   : { username : username , password : password }

    res =
      redirect: (target)->
        target.assert_Is(expected_Target)
        callback()

    using new Login_Controller(req, res), ->
      @.webServices = url_WebServices
      @.loginUser()


  it 'userSignUp (webServices - bad server)', (done)->
    username    = 'a'.add_5_Random_Letters()
    password    = 'b'.add_5_Random_Letters()
    email       = 'c'.add_5_Letters() + "@".add_5_Letters()
    firstname   = 'd'.add_5_Random_Letters()
    lastname    = 'e'.add_5_Random_Letters()
    country     = 'f'.add_5_Random_Letters()
    req = body : {username: username,password: password,"confirm-password": password,email: email,firstname:firstname,lastname:lastname,company:undefined ,title:undefined ,country:country}
    render_Page = (jade_Page, params)->
        jade_Page.assert_Is signUpPage_Unavailable
        params.assert_Is { viewModel:{username: username,password: password,"confirmpassword": password,email: email,firstname:firstname,lastname:lastname,company:undefined ,title:undefined ,country:country,state:undefined,errorMessage: 'TEAM Mentor is unavailable, please contact us at '} }
        done()

    using new User_Sign_Up_Controller(req,null),->
      @.render_Page = render_Page
      @.webServices = "http://aaaaaaa.teammentor.net"
      @userSignUp()

  it 'userSignUp (webServices - non 200 response)', (done)->
    on_CreateUser_Response = (req,res)->
      res.status(201).send {}

    username    = 'a'.add_5_Random_Letters()
    password    = 'b'.add_5_Random_Letters()
    email       = 'c'.add_5_Letters() + "@".add_5_Letters()
    firstname   = 'd'.add_5_Random_Letters()
    lastname    = 'e'.add_5_Random_Letters()
    country     = 'f'.add_5_Random_Letters()
    req = body : {username: username,password: password,"confirm-password": password,email: email,firstname:firstname,lastname:lastname,company:undefined ,title:undefined ,country:country}

    render_Page = (jade_Page, params)->
        jade_Page.assert_Is signUpPage_Unavailable
        params.assert_Is { viewModel:{username: username,password: password,confirmpassword: password,email: email,firstname:firstname,lastname:lastname,company:undefined ,title:undefined ,country:country,state:undefined,errorMessage: 'TEAM Mentor is unavailable, please contact us at '} }
        done()

    using new User_Sign_Up_Controller(req,null),->
      @.render_Page = render_Page
      @.webServices = url_WebServices
      @userSignUp()

  it 'userSignUp (webServices - null response)', (done)->
    on_CreateUser_Response = (req,res)->
      res.send null

    username    = 'a'.add_5_Random_Letters()
    password    = 'b'.add_5_Random_Letters()
    email       = 'c'.add_5_Letters() + "@".add_5_Letters()
    firstname   = 'd'.add_5_Random_Letters()
    lastname    = 'e'.add_5_Random_Letters()
    country     = 'f'.add_5_Random_Letters()
    req = body : {username: username,password: password,"confirm-password": password,email: email,firstname:firstname,lastname:lastname,company:undefined ,title:undefined ,country:country}

    render_Page = (jade_Page, params)->
      jade_Page.assert_Is signUpPage_Unavailable
      params.assert_Is { viewModel: { errorMessage: 'An error occurred' } }
      done()

    using new User_Sign_Up_Controller(req,null),->
      @.render_Page =render_Page
      @.webServices = url_WebServices
      @userSignUp()

  it 'userSignUp (webServices - non json response)', (done)->
    on_CreateUser_Response = (req,res)->
      res.send 'aaaaaa'

    username    = 'a'.add_5_Random_Letters()
    password    = 'b'.add_5_Random_Letters()
    email       = 'c'.add_5_Letters() + "@".add_5_Letters()
    firstname   = 'd'.add_5_Random_Letters()
    lastname    = 'e'.add_5_Random_Letters()
    country     = 'f'.add_5_Random_Letters()
    req = body : {username: username,password: password,"confirm-password": password,email: email,firstname:firstname,lastname:lastname,company:undefined ,title:undefined ,country:country}

    render_Page = (jade_Page, params)->
        jade_Page.assert_Is signUpPage_Unavailable
        params.assert_Is { viewModel: { errorMessage: 'An error occurred' } }
        done()

    using new User_Sign_Up_Controller(req,null),->
      @.render_Page = render_Page
      @.webServices = url_WebServices
      @userSignUp()

  it 'userSignUp (bad values)', (done)->
    on_CreateUser_Response = null
    username     = 'a'.add_5_Random_Letters()
    password     = 'b*Cr87aCK'.add_5_Random_Letters()
    weakPassword = 'abc'
    email        = 'c'.add_5_Letters() + "@".add_5_Letters()
    firstname    = 'd'.add_5_Random_Letters()
    lastname     = 'e'.add_5_Random_Letters()
    country      = 'f'.add_5_Random_Letters()

    invoke_UserSignUp              ''      ,password     ,password     ,email,firstname,lastname,country,signUp_fail, text_username_Required        ,->  #empty username
      invoke_UserSignUp            username,''           ,password     ,email,firstname,lastname,country,signUp_fail, text_password_Required        ,->  #empty password
        invoke_UserSignUp          username,password     ,''           ,email,firstname,lastname,country,signUp_fail, text_confirmpassword_Required ,->  #empty confirm
          invoke_UserSignUp        username,password     ,'Abc288**398',email,firstname,lastname,country,signUp_fail, text_password_NoMatch         ,->  #passwords do not match
          invoke_UserSignUp        username,weakPassword ,weakPassword ,email,firstname,lastname,country,signUp_fail, text_Short_Pwd                ,->  #weak password
            invoke_UserSignUp      username,password     ,password     ,''   ,firstname,lastname,country,signUp_fail, text_email_Required           ,->  #email is required
            invoke_UserSignUp      username,password     ,password     ,email,''       ,lastname,country,signUp_fail, text_firstName_Required       ,->  #firstname is required
              invoke_UserSignUp    username,password     ,password     ,email,firstname,''      ,country,signUp_fail, text_lastName_Required        ,->  #lastName is required
                invoke_UserSignUp  username,password     ,password     ,email,firstname,lastname,''     ,signUp_fail, text_country_Required         ,->  #country is required
                  done()

  it 'userSignUp (good values)', (done)->
    user      = "tm_ut_".add_5_Random_Letters()
    pwd       = "**tm**pwd**"
    email     = "#{user}@teammentor.net"
    Firstname = "Foo"
    Lastname  = "Bar"
    #Company   = "Temp"
    #Title     = "Engineering"
    Country   =  "US"
    #State     = "California"

    invoke_UserSignUp user,pwd,pwd,email,Firstname,Lastname,Country,mainPage_user,'', ->
      invoke_LoginUser user,pwd,mainPage_user, ->
        done()

  it 'userSignUp (pwd dont match)', (done)->
    req =
      body   : { password:'aa' , 'password-confirm':'bb'}

    render_Page = (target) ->
        target.assert_Contains(signUp_fail)
        done()

    using new User_Sign_Up_Controller(req, null),->
      @.render_Page = render_Page
      @.webServices = url_WebServices
      @userSignUp()


  it 'userSignUp (error handling)', (done)->
    username    = 'a'.add_5_Random_Letters()
    password    = 'b'.add_5_Random_Letters()
    email       = 'c'.add_5_Letters() + "@".add_5_Letters()
    firstname   = 'd'.add_5_Random_Letters()
    lastname    = 'e'.add_5_Random_Letters()
    country     = 'f'.add_5_Random_Letters()
    req = body : {username: username,password: password,"confirm-password": password,email: email,firstname:firstname,lastname:lastname,company:undefined ,title:undefined ,country:country}

    render_Page = (jade_Page, params)->
        jade_Page.assert_Is signUpPage_Unavailable
        params.assert_Is { viewModel:{ username: username,password:password,confirmpassword:password,email: email,firstname:firstname,lastname:lastname,company:undefined ,title:undefined ,country:country,state:undefined,errorMessage: 'TEAM Mentor is unavailable, please contact us at '} }
        done()
    using new User_Sign_Up_Controller(req,null),->
      @.render_Page = render_Page
      @.webServices = 'https://aaaaaaaa.teammentor.net/'
      @userSignUp()

  it 'Persist HTML form fields on error (username is required)',(done)->
    newUsername         =''
    newPassword         ='aa'.add_5_Letters()
    newConfirmPassword  ='bb'.add_5_Letters()
    newEmail            ='ab'.add_5_Letters()+'@mailinator.com'

    #render contains the file to render and the view model object
    render_Page = (html,model)->
      model.viewModel.username.assert_Is(newUsername)
      model.viewModel.password.assert_Is(newPassword)
      model.viewModel.confirmpassword.assert_Is(newConfirmPassword)
      model.viewModel.email.assert_Is(newEmail)
      model.viewModel.errorMessage.assert_Is(text_username_Required)
      done()
    req = body:{username:newUsername,password:newPassword,'confirm-password':newConfirmPassword, email:newEmail};

    using new User_Sign_Up_Controller(req, null), ->
      @.render_Page = render_Page
      @.userSignUp()

  it 'Persist HTML form fields on error (password is required)',(done)->
    newUsername         ='xy'.add_5_Letters()
    newPassword         =''
    newConfirmPassword  ='bb'.add_5_Letters()
    newEmail            ='ab'.add_5_Letters()+'@mailinator.com'

    #render contains the file to render and the view model object
    render_Page = (html,model)->
      model.viewModel.username.assert_Is(newUsername)
      model.viewModel.password.assert_Is(newPassword)
      model.viewModel.confirmpassword.assert_Is(newConfirmPassword)
      model.viewModel.email.assert_Is(newEmail)
      model.viewModel.errorMessage.assert_Is(text_password_Required)
      done()
    req = body:{username:newUsername,password:newPassword,'confirm-password':newConfirmPassword, email:newEmail};

    using new User_Sign_Up_Controller(req, null), ->
      @.render_Page = render_Page
      @.userSignUp()

  it 'Persist HTML form fields on error (confirm password is required)',(done)->
    newUsername         ='xy'.add_5_Letters()
    newPassword         ='bb'.add_5_Letters()
    newConfirmPassword  =''
    newEmail            ='ab'.add_5_Letters()+'@mailinator.com'

    #render contains the file to render and the view model object
    render_Page = (html,model)->
      model.viewModel.username.assert_Is(newUsername)
      model.viewModel.password.assert_Is(newPassword)
      model.viewModel.confirmpassword.assert_Is(newConfirmPassword)
      model.viewModel.email.assert_Is(newEmail)
      model.viewModel.errorMessage.assert_Is(text_confirmpassword_Required)
      done()
    req = body:{username:newUsername,password:newPassword,'confirm-password':newConfirmPassword, email:newEmail};

    using new User_Sign_Up_Controller(req, null), ->
      @.render_Page = render_Page
      @.userSignUp()

  it 'Persist HTML form fields on error (Passwords do not match)',(done)->
    newUsername         ='xy'.add_5_Letters()
    newPassword         ='aa'.add_5_Letters()
    newConfirmPassword  ='bb'.add_5_Letters()
    newEmail            ='ab'.add_5_Letters()+'@mailinator.com'

    #render contains the file to render and the view model object
    render_Page = (html,model)->
        model.viewModel.username.assert_Is(newUsername)
        model.viewModel.password.assert_Is(newPassword)
        model.viewModel.confirmpassword.assert_Is(newConfirmPassword)
        model.viewModel.email.assert_Is(newEmail)
        model.viewModel.errorMessage.assert_Is('Passwords don\'t match')
        done()
    req = body:{username:newUsername,password:newPassword,'confirm-password':newConfirmPassword, email:newEmail};

    using new User_Sign_Up_Controller(req, null), ->
      @.render_Page = render_Page
      @.userSignUp()

  it 'Persist HTML form fields on error (Password too short)',(done)->
    newUsername         ='xy'.add_5_Letters()
    newPassword         ='aa'.add_5_Letters()
    newEmail            ='ab'.add_5_Letters()+'@mailinator.com'
    firstName           ='aa'.add_5_Letters()
    lastName            ='aa'.add_5_Letters()
    company             ='aa'.add_5_Letters()
    title               ='aa'.add_5_Letters()
    country             ='aa'.add_5_Letters()
    state               ='aa'.add_5_Letters()
    #render contains the file to render and the view model object
    render_Page = (html,model)->
      model.viewModel.username.assert_Is(newUsername)
      model.viewModel.password.assert_Is(newPassword)
      model.viewModel.confirmpassword.assert_Is(newPassword)
      model.viewModel.email.assert_Is(newEmail)
      model.viewModel.firstname.assert_Is(firstName)
      model.viewModel.lastname.assert_Is(lastName)
      model.viewModel.company.assert_Is(company)
      model.viewModel.title.assert_Is(title)
      model.viewModel.country.assert_Is(country)
      model.viewModel.state.assert_Is(state)
      model.viewModel.errorMessage.assert_Is('Password must be 8 to 256 character long')
      done()
    req = body:{username:newUsername,password:newPassword,'confirm-password':newPassword, email:newEmail,firstname:firstName,lastname:lastName,company:company,title:title,country:country,state:state};


    using new User_Sign_Up_Controller(req, null), ->
      @.render_Page = render_Page
      @.webServices = url_WebServices
      @.userSignUp()

  it 'Persist HTML form fields on error (email)',(done)->
    newUsername         ='aa'.add_5_Letters()
    newPassword         ='aa'.add_5_Letters()
    newEmail            =''

    #render contains the file to render and the view model object
    render_Page = (html,model)->
      model.viewModel.username.assert_Is(newUsername)
      model.viewModel.password.assert_Is(newPassword)
      model.viewModel.confirmpassword.assert_Is(newPassword)
      model.viewModel.email.assert_Is(newEmail)
      model.viewModel.errorMessage.assert_Is(text_email_Required)
      done()
    req = body:{username:newUsername,password:newPassword,'confirm-password':newPassword, email:newEmail};

    using new User_Sign_Up_Controller(req, null), ->
      @.render_Page = render_Page
      @.userSignUp()

  it 'Persist HTML form fields on error (Firstname is required)',(done)->
    newUsername         ='xy'.add_5_Letters()
    newPassword         ='aaa'.add_5_Letters()
    newEmail            ='ab'.add_5_Letters()+'@mailinator.com'
    firstName           = ''
    lastName            ='aa'.add_5_Letters()
    company             ='aa'.add_5_Letters()
    title               ='aa'.add_5_Letters()
    country             ='aa'.add_5_Letters()
    state               ='aa'.add_5_Letters()
    #render contains the file to render and the view model object
    render_Page = (html,model)->
      model.viewModel.username.assert_Is(newUsername)
      model.viewModel.password.assert_Is(newPassword)
      model.viewModel.confirmpassword.assert_Is(newPassword)
      model.viewModel.email.assert_Is(newEmail)
      model.viewModel.firstname.assert_Is(firstName)
      model.viewModel.lastname.assert_Is(lastName)
      model.viewModel.company.assert_Is(company)
      model.viewModel.title.assert_Is(title)
      model.viewModel.country.assert_Is(country)
      model.viewModel.state.assert_Is(state)
      model.viewModel.errorMessage.assert_Is(text_firstName_Required)
      done()
    req = body:{username:newUsername,password:newPassword,'confirm-password':newPassword, email:newEmail,firstname:firstName,lastname:lastName,company:company,title:title,country:country,state:state};


    using new User_Sign_Up_Controller(req, null), ->
      @.render_Page = render_Page
      @.webServices = url_WebServices
      @.userSignUp()

  it 'Persist HTML form fields on error (Last is required)',(done)->
    newUsername         ='xy'.add_5_Letters()
    newPassword         ='aaa'.add_5_Letters()
    newEmail            ='ab'.add_5_Letters()+'@mailinator.com'
    firstName           ='aa'.add_5_Letters()
    lastName            =''
    company             ='aa'.add_5_Letters()
    title               ='aa'.add_5_Letters()
    country             ='aa'.add_5_Letters()
    state               ='aa'.add_5_Letters()
    #render contains the file to render and the view model object
    render_Page = (html,model)->
      model.viewModel.username.assert_Is(newUsername)
      model.viewModel.password.assert_Is(newPassword)
      model.viewModel.confirmpassword.assert_Is(newPassword)
      model.viewModel.email.assert_Is(newEmail)
      model.viewModel.firstname.assert_Is(firstName)
      model.viewModel.lastname.assert_Is(lastName)
      model.viewModel.company.assert_Is(company)
      model.viewModel.title.assert_Is(title)
      model.viewModel.country.assert_Is(country)
      model.viewModel.state.assert_Is(state)
      model.viewModel.errorMessage.assert_Is(text_lastName_Required)
      done()
    req = body:{username:newUsername,password:newPassword,'confirm-password':newPassword, email:newEmail,firstname:firstName,lastname:lastName,company:company,title:title,country:country,state:state};


    using new User_Sign_Up_Controller(req, null), ->
      @.render_Page = render_Page
      @.webServices = url_WebServices
      @.userSignUp()

  it 'Persist HTML form fields on error (Country required)',(done)->
    newUsername         ='xy'.add_5_Letters()
    newPassword         ='aaa'.add_5_Letters()
    newEmail            ='ab'.add_5_Letters()+'@mailinator.com'
    firstName           ='aa'.add_5_Letters()
    lastName            ='aa'.add_5_Letters()
    company             ='aa'.add_5_Letters()
    title               ='aa'.add_5_Letters()
    country             =''
    state               ='aa'.add_5_Letters()

    #render contains the file to render and the view model object
    render_Page = (html,model)->
      model.viewModel.username.assert_Is(newUsername)
      model.viewModel.password.assert_Is(newPassword)
      model.viewModel.confirmpassword.assert_Is(newPassword)
      model.viewModel.email.assert_Is(newEmail)
      model.viewModel.firstname.assert_Is(firstName)
      model.viewModel.lastname.assert_Is(lastName)
      model.viewModel.company.assert_Is(company)
      model.viewModel.title.assert_Is(title)
      model.viewModel.country.assert_Is(country)
      model.viewModel.state.assert_Is(state)
      model.viewModel.errorMessage.assert_Is(text_country_Required)
      done()
    req = body:{username:newUsername,password:newPassword,'confirm-password':newPassword, email:newEmail,firstname:firstName,lastname:lastName,company:company,title:title,country:country,state:state};


    using new User_Sign_Up_Controller(req, null), ->
      @.render_Page = render_Page
      @.webServices = url_WebServices
      @.userSignUp()