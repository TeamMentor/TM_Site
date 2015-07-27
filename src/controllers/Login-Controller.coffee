request                    = null
analytics_Service          = null
Jade_Service               = null
blank_credentials_message  = 'Invalid Username or Password'
loginSuccess               = 0
errorMessage               = "TEAM Mentor is unavailable, please contact us at "

class Login_Controller
  dependencies: ->
    request             = require('request')
    analytics_Service   = require('../services/Analytics-Service')
    Jade_Service        = require('../services/Jade-Service')

  constructor: (req, res)->
    @.dependencies()

    @.req                = req || {}
    @.res                = res || {}
    @.webServices        = "#{global.config?.tm_design?.tm_35_Server}#{global.config?.tm_design?.webServices}"
    @.tm_35_Server       = global.config?.tm_design?.tm_35_Server
    @.analyticsService   = new analytics_Service(@.req, @.res)
    @.jade_Service       = new Jade_Service()

    @.jade_LoginPage             = 'guest/login-Fail.jade'
    @.jade_LoginPage_Unavailable = 'guest/login-cant-connect.jade'
    @.jade_GuestPage_403         = 'guest/403.jade'
    @.page_MainPage_user         = '/user/main.html'
    @.page_MainPage_no_user      = '/guest/default.html'

  json_Mode: ()=>
    @.render_Page = (page, data)=>
      data.page = page
      @.res.json data
    @.res.redirect = (page)=>
      data =
        page     : page
        viewModel: {}
        result   : 'OK'
      @.res.json data
    @

  loginUser: ()=>

    userViewModel ={username: @.req.body.username,password:'',errorMessage:''}

    if (@.req.body.username == '' or @.req.body.password == '')
      @.req.session.username      = undefined
      userViewModel.errorMessage  = blank_credentials_message
      return @.render_Page @.jade_LoginPage,{viewModel:userViewModel}

    username = @.req.body.username
    password = @.req.body.password

    options =
      method : 'post',
      body   : { username:username, password:password },
      json   : true,
      url    : "#{@.webServices}/Login_Response"

    console.log options.url

    request options, (error, response)=>
      if error
        console.log error
        logger?.info ('Could not connect with TM 3.5 server')
        console.log (errorMessage)
        userViewModel.errorMessage = errorMessage
        userViewModel.username =''
        userViewModel.password=''
        return @.render_Page @.jade_LoginPage_Unavailable, {viewModel:userViewModel }
      if not (response?.body?.d)
        console.log options.url
        console.log response.body
        logger?.info ('Could not connect with TM 3.5 server')
        userViewModel.errorMessage = errorMessage
        userViewModel.username =''
        userViewModel.password=''
        return @.render_Page @.jade_LoginPage_Unavailable, {viewModel:userViewModel }

      loginResponse   = response.body.d
      success         = loginResponse?.Login_Status
      if (success == loginSuccess)
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
              @.res.redirect(redirectUrl)
            else
              @.res.redirect(@.page_MainPage_user)
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
    @.res.redirect(@.page_MainPage_no_user)

  render_Page: (page, view_Model)=>
    @.res.send @.jade_Service.render_Jade_File page, view_Model

  webServiceResponse: (methodName,Token,callback)->
    options =
      method: 'post',
      body: {},
      json: true,
      headers: {'Cookie':'Session='+Token}
      url: @.webServices + '/' + methodName
    request options, (error, response)=>
      if error
        logger?.info ('Could not connect with TM 3.5 server')
        callback null
      else
        callback response?.body?.d

  redirectIfPasswordExpired: (token,callback)->
    @.webServiceResponse "Current_User",token,(userProfile)=>
      if(userProfile?.PasswordExpired)
        @.webServiceResponse "GetCurrentUserPasswordExpiryUrl",token,(url)->
          callback url
      else
        callback null

  tm_SSO: ()=>
    username = @.req.query.username || @.req.query.userName
    token    = @.req.query.requestToken
    format   = @.req.query.format

    if username and token
      server = @.tm_35_Server
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


module.exports = Login_Controller
