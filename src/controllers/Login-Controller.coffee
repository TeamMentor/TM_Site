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
    @.sessionTimeout_In_Minutes  = @.config.options.tm_design.session_Timeout_Minutes
    @.debugEnabled               = @.config?.options?.tm_debug?.debugEnabled

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
        @.analyticsService.track()
        @.req?.session?.token = loginResponse.Token
        #If Password was expired,
        @.redirectIfPasswordExpired loginResponse.Token,(redirectUrl)=>
          if(redirectUrl)
            @.url =redirectUrl
            @.res.redirect(redirectUrl)
          else
            @.analyticsService.track('Login','User Account','Login Success')
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
        @.analyticsService.track('Login','User Account','Login Failed')
        if (loginResponse?.Validation_Results?.not_Empty())
          userViewModel.errorMessage  = loginResponse.Validation_Results.first().Message

        else
          userViewModel.errorMessage  = loginResponse?.Simple_Error_Message

        @.render_Page @.jade_LoginPage,{ viewModel:userViewModel }

  logoutUser: ()=>
    @.req.session.username = undefined
    token = @.req?.session?.token
    @.webServiceResponse "Logout",token,(response)=>
      @.analyticsService.track('Logout','User Account',"Logout")
      @.req?.session?.destroy()
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
      cookieExpirationDate = new Date(@.req.session.cookie.expires)                     #Expiration defined in config
      userExpiration       = new Date(parseInt(userProfile?.ExpirationDate?.substr(6))) #TM backend expiration.

      @.debugEnabled && console.log("TM 3.6 user expires on " + userExpiration)
      @.debugEnabled && console.log("Cookie Expires on      " + cookieExpirationDate)

      #If AccountNeverExpires, then expiration date becomes : Current Date + Minutes configured in config.
      if (userProfile?.AccountNeverExpires)
        currentTime = new Date()
        currentTime.setMinutes(currentTime.getMinutes() + @.sessionTimeout_In_Minutes)
        @.req.session.sessionExpirationDate = currentTime;
      else
        if (userExpiration > cookieExpirationDate)
          @.req.session.sessionExpirationDate = cookieExpirationDate
        else
          @.req.session.sessionExpirationDate = userExpiration
          @.req.session.cookie.expires        = userExpiration

      @.debugEnabled && console.log("After recalculating dates :")
      @.debugEnabled && console.log("Session expires on " + @.req.session.sessionExpirationDate)
      @.debugEnabled && console.log("Cookie Expires on  " + @.req.session.cookie.expires)

      @.verifyInternalUser userProfile?.Email
      #Redirect to password reset page
      if(userProfile?.PasswordExpired && not userProfile?.AccountNeverExpires)
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
    @.req?.session?.userEmail    = userEmail

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
    #Analytics, tracking SSO URl
    url = @.req.protocol + '://' + @.req.get('host') + @.req.originalUrl;
    @.analyticsService.trackUrl(url)

    username = @.req.query.username || @.req.query.userName
    token    = @.req.query.requestToken
    format   = @.req.query.format
    @.req.session.ssoUser = true
    if username and token
      if (@.req.session.username? && @.req.session.username == username)
        @.res.set('P3P',"CP=\'IDC DSP COR DEVo OUR\'")
        if format?
          @.res.writeHead(200, {'Content-Type': 'image/gif' });
          @.res.write(@.get_GifImage())
          return @.res.end()
        else
          return @.res.redirect '/'

      server = @.url_Tm_35_Server()
      path   = @.req.route.path.substring(1)
      url    = "#{server}/#{path}?username=#{username}&requestToken=#{token}"
      if (format?)
        url = url + "&format=#{format}"
      options =
        url: url
        followRedirect: false

      request options,(error, response)=>

        #Parsing response cookie to get the authenticated token
        cookie    = response?.headers?['set-cookie']
        sessionId = cookie?.toString().split(',')[1]
        sessionId = sessionId.split('=')[1] if sessionId?.split('=')?

        @.res.set('P3P',"CP=\'IDC DSP COR DEVo OUR\'")

        if response.headers?.location is '/teammentor'
          @.analyticsService.track('SSO Login','User Account','Login Success')
          @.req.session.username = username
          @.req.session.token    = sessionId if sessionId?
          @.webServiceResponse "Current_User",sessionId,(userProfile)=>
            @.req.session.sessionExpirationDate = new Date(parseInt(userProfile?.ExpirationDate?.substr(6)))
            return @.res.redirect '/'
        else
          if (response.headers?['content-type']=='image/gif')
            @.analyticsService.track('SSO Login','User Account','Login Success')
            @.req.session.username = username
            @.req.session.token    = sessionId if sessionId?
            @.webServiceResponse "Current_User",sessionId,(userProfile)=>
              @.req.session.sessionExpirationDate = new Date(parseInt(userProfile?.ExpirationDate?.substr(6)))
              @.res.writeHead(200, {'Content-Type': 'image/gif' });
              @.res.write(@.get_GifImage())
              return @.res.end()
          else
            @.analyticsService.track('SSO Login Fail','User Account','SSO Login Fail')
            @.res.send @.jade_Service.render_Jade_File @.jade_GuestPage_403
    else
      @.analyticsService.track('SSO Login Fail','User Account','SSO Login Fail')
      @.res.send @.jade_Service.render_Jade_File  @.jade_GuestPage_403

  #returns a gif image in base64
  get_GifImage: () =>
    gifImage = new Buffer('R0lGODlhAQABAPcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAP8ALAAAAAABAAEAAAgEAP8FBAA7', 'base64')
    return gifImage

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
