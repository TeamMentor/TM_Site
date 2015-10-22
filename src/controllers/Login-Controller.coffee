request                    = null
Router                     = null
analytics_Service          = null
Jade_Service               = null
blank_credentials_message  = 'Invalid Username or Password'
loginSuccess               = 0
errorMessage               = "TEAM Mentor is unavailable, please contact us at "
User_Sign_Up_Controller    = null
user_data_cache            = {};

class Login_Controller
  dependencies: ->
    {Router}                = require 'express'
    request                 = require 'request'
    analytics_Service       = require '../services/Analytics-Service'
    Jade_Service            = require '../services/Jade-Service'
    User_Sign_Up_Controller = require './User-Sign-Up-Controller'


  constructor: (req, res)->
    @.dependencies()
    @.config            = require '../config'

    @.req                = req || {}
    @.res                = res || {}
    @.analyticsService   = new analytics_Service(@.req, @.res)
    @.jade_Service       = new Jade_Service()

    @.jade_LoginPage             = 'guest/login-Fail.jade'
    @.jade_LoginPage_Unavailable = 'guest/login-cant-connect.jade'
    @.jade_GuestPage_403         = 'guest/403.jade'
    @.page_Index                 = '/jade/show'
    @.page_MainPage_no_user      = '/jade/guest/default.html'
    @.url                        = ''

  json_Mode: ()=>
    @.render_Page = (page, data)=>
      data.page = page
      @.res.json data
    @.res.redirect = (page)=>
      data =
        page     : page
        viewModel: {redirectUrl:@.url}
        result   : 'OK'
      @.res.json data
    @

  loginUser: ()=>
    @.url         =''
    userViewModel = {username: @.req.body.username,password:'',errorMessage:''}

    if (@.req.body.username == '' or @.req.body.password == '')
      @.req.session.username      = undefined
      userViewModel.errorMessage  = blank_credentials_message
      return @.render_Page @.jade_LoginPage,{viewModel:userViewModel}

    username = @.req.body.username
    password = @.req.body.password

    if (false)     # bypasses login
      @.req.session.username = username
      @.res.redirect(@.page_Index)
      return

    options =
      method : 'post',
      body   : { username:username, password:password },
      json   : true,
      url    : "#{@.url_WebServices()}/Login_Response"

    request options, (error, response)=>
      if error
        #console.log error
        logger?.info ('Could not connect with TM 3.5 server')
        #console.log (errorMessage)
        userViewModel.errorMessage = errorMessage
        userViewModel.username =''
        userViewModel.password=''
        return @.render_Page @.jade_LoginPage_Unavailable, {viewModel:userViewModel }
      if not (response?.body?.d)
        logger?.info ('Could not connect with TM 3.5 server')
        userViewModel.errorMessage = errorMessage
        userViewModel.username =''
        userViewModel.password=''
        return @.render_Page @.jade_LoginPage_Unavailable, {viewModel:userViewModel }

      loginResponse   = response.body.d
      success         = loginResponse?.Login_Status
      if (success == loginSuccess)
        @.req?.session?.token = loginResponse.Token
        #If Password was expired,
        @.redirectIfPasswordExpired loginResponse.Token,(redirectUrl)=>
          if(redirectUrl)
            @.res.redirect(redirectUrl)
          else
            @.analyticsService.track('','User Account','Login Success')
            @.req.session.username = username
            redirectUrl            = @.req.session.redirectUrl

            if(redirectUrl?.is_Local_Url())
              delete @.req.session.redirectUrl
              @.url =redirectUrl
              @.res.redirect(redirectUrl)
            else
              @.url ='' #cleaning up variable
              @.res.redirect(@.page_Index)
      else
        @.req.session.username = undefined
        @.analyticsService.track('','User Account','Login Failed')
        if (loginResponse?.Validation_Results?.not_Empty())
          userViewModel.errorMessage  = loginResponse.Validation_Results.first().Message
        else
          userViewModel.errorMessage  = loginResponse?.Simple_Error_Message

        @.render_Page @.jade_LoginPage,{ viewModel:userViewModel }

  logoutUser: ()=>
    @.req.session.username = undefined
    token = @.req?.session?.token
    @.webServiceResponse "Logout",token,(response)=>
      @.req?.session?.token = undefined
      @.res.redirect(@.page_MainPage_no_user)

  render_Page: (page, view_Model)=>
    @.res.send @.jade_Service.render_Jade_File page, view_Model

  url_WebServices: ()=>
    "#{@.config.options.tm_design?.tm_35_Server}#{@.config.options.tm_design?.webServices}"

  url_Tm_35_Server: ()=>
    @.config.options.tm_design?.tm_35_Server

  webServiceResponse: (methodName,Token,callback)->
    options =
      method: 'post',
      body: {},
      json: true,
      headers: {'Cookie':'Session='+Token}
      url: @.url_WebServices() + '/' + methodName
    request options, (error, response)=>
      if error
        logger?.info ('Could not connect with TM 3.5 server')
        callback null
      else
        callback response?.body?.d

  redirectIfPasswordExpired: (token,callback)->
    @.webServiceResponse "Current_User",token,(userProfile)=>
      #Setting up internal user
      @.verifyInternalUser userProfile?.Email
      if(userProfile?.PasswordExpired)
        @.webServiceResponse "GetCurrentUserPasswordExpiryUrl",token,(url)->
          callback url
      else
        callback null

  verifyInternalUser: (userEmail)->
    internalUser                     = false
    allowedEmailDomains              = @.config.options.tm_design?.allowedEmailDomains
    email                            = userEmail

    allowedEmailDomains?.some (domain)->
      if email?.match(domain.toString())
        internalUser = true
        
    @.req?.session?.internalUser = internalUser

  currentUser : ()->
    token = @.req?.session?.token
    if token
      return @.res.json user_data_cache[token] if  user_data_cache[token]?
      @.webServiceResponse "Current_User",token,(userProfile)=>
        user_data_cache[token] = userProfile
        @.res.json userProfile
    else
      return @.res.json []

  tm_SSO: ()=>
    username = @.req.query.username || @.req.query.userName
    token    = @.req.query.requestToken
    format   = @.req.query.format

    if username and token
      server = @.url_Tm_35_Server()
      path   = @.req.route.path.substring(1)
      url    = "#{server}/#{path}?username=#{username}&requestToken=#{token}"
      if (format?)
        url = url + "&format=#{format}"
      options =
        url: url
        followRedirect: false

      request options,(error, response)=>
        if response.headers?.location is '/teammentor'
          @.req.session.username = username
          return @.res.redirect '/'
        else
          if (response.headers?['content-type']=='image/gif')
            @.req.session.username = username
            gifImage = new Buffer('R0lGODlhAQABAPcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAP8ALAAAAAABAAEAAAgEAP8FBAA7', 'base64')
            @.res.writeHead(200, {'Content-Type': 'image/gif' });
            @.res.write(gifImage)
            return @.res.end()
        @.res.send @.jade_Service.render_Jade_File @.jade_GuestPage_403
    else
      @.res.send @.jade_Service.render_Jade_File  @.jade_GuestPage_403


  routes_Json: ()=>
    using new Router(), ->
      @.post '/json/user/login'         , (req, res)-> new Login_Controller(req, res).json_Mode().loginUser()
      @.post '/json/user/logout'        , (req, res)-> new Login_Controller(req, res).json_Mode().logoutUser()
      @.get  '/json/user/currentuser'   , (req, res)-> new Login_Controller(req, res).json_Mode().currentUser()
      @.post '/json/user/signup'        , (req, res)-> new User_Sign_Up_Controller(req, res).json_Mode().userSignUp()

  routes_Jade: ()=>
    using new Router(), ->
      @.post '/user/login'              , (req, res)-> new Login_Controller(req, res).loginUser()
      @.get  '/user/logout'             , (req, res)-> new Login_Controller(req, res).logoutUser()
      @.post '/user/sign-up'            , (req, res)-> new User_Sign_Up_Controller(req, res).userSignUp();

  routes_SSO: ()=>
    using new Router(), ->
      @.get '/_Customizations/SSO.aspx' , (req, res)-> new Login_Controller(req, res).tm_SSO()
      @.get '/Aspx_Pages/SSO.aspx'      , (req, res)-> new Login_Controller(req, res).tm_SSO()

module.exports = Login_Controller
