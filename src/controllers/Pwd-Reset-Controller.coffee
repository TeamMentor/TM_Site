request      = null
Router       = null
Config       = null
Jade_Service = null

class Pwd_Reset_Controller

  dependencies: ->
    request      = require 'request'
    {Router}     = require 'express'
    Jade_Service = require '../services/Jade-Service'

  constructor: (req, res, options)->
    @.dependencies()

    @.options                      = options || {}
    @.req                          = req
    @.res                          = res
    @.request_Timeout              = @.options.request_Timeout || 1500
    @.webServices                  = @.options.webServices ||"#{global.config?.tm_design?.tm_35_Server}#{global.config?.tm_design?.webServices}"
    @.jade_loginPage_Unavailable   = 'guest/login-cant-connect.jade'
    @.jade_password_reset_fail     = 'guest/pwd-reset-fail.jade'
    @.jade_password_reset          = 'guest/pwd-reset.jade'
    @.url_password_reset_ok        = '/jade/guest/login-pwd-reset.html'
    @.url_password_sent            = '/jade/guest/pwd-sent.html'
    @.url_WS_SendPasswordReminder  = @.webServices + '/SendPasswordReminder'
    @.url_WS_PasswordReset         = @.webServices + '/PasswordReset'
    @.url_error_page               = '/error'
    @.errorMessage                 = "TEAM Mentor is unavailable, please contact us at "
    @.okMessage                    = "If you entered a valid address, then a password reset link has been sent to your email address."
    @.jade_Service                 = new Jade_Service()

  json_Mode: =>
    @.res.redirect = => @.res.json { message: @.okMessage    , status: 'Ok'    }
    @.render_Page  = => @.res.json { message: @.errorMessage , status: 'Failed'}
    @


  password_Reset: ()=>

    email = @.req?.body?.email

    options = {
                    method : 'post'
                    body   : {email: email}
                    json   : true
                    url    : @.url_WS_SendPasswordReminder
              }

    request options, (error, response)=>
      if ((not error) and response?.statusCode == 200)
          @.res.redirect(@.url_password_sent);
      else
          logger?.info ('Could not connect with TM 3.5 server')
          userViewModel = {errorMessage:@.errorMessage,username:'',password:''}
          return @.render_Page @.jade_loginPage_Unavailable, {viewModel:userViewModel }

  password_Reset_Page: ()=>
    @.render_Page @.jade_password_reset

  password_Reset_Token : ()=>

    username = @.req.params?.username
    token    = @.req.params?.token

    passwordStrengthRegularExpression =///(
        (?=.*\d)            # at least 1 digit
        (?=.*[A-Z])         # at least 1 upper case letter
        (?=.*[a-z])         # at least 1 lower case letter
        (?=.*\W)            # at least 1 special character
        .                   # match any with previous validations
        {8,256}             # 8 to 256 characters
       )///

    #Validating token
    if (token == null or username == null or username is '' or token is '')
      @.errorMessage = 'Token is invalid'
      return @.render_Page @.jade_password_reset_fail, {errorMessage: 'Token is invalid'}

    #Password not provided
    if (@.req.body?.password?.length is 0)
      @.errorMessage = 'Password must not be empty'
      return @.render_Page @.jade_password_reset_fail, {errorMessage: 'Password must not be empty'}

    #Confirmation password not provided
    if (@.req.body?['confirm-password']?.length is 0)
      @.errorMessage = 'Confirmation Password must not be empty'
      return @.render_Page @.jade_password_reset_fail, {errorMessage: 'Confirmation Password must not be empty'}

    #Passwords must match
    if (@.req.body?.password != @.req.body?['confirm-password'])
      @.errorMessage ='Passwords don\'t match'
      return @.render_Page @.jade_password_reset_fail, {errorMessage: 'Passwords don\'t match'}
    #length check
    if (@.req.body?.password?.length < 8 || @.req.body?.password?.length > 256 )
      @.errorMessage ='Password must be 8 to 256 character long'
      return @.render_Page @.jade_password_reset_fail, {errorMessage: 'Password must be 8 to 256 character long'}

    #Complexity
    if (!@.req.body?.password?.match(passwordStrengthRegularExpression))
      @.errorMessage ='Your password should be at least 8 characters long. It should have one uppercase and one lowercase letter, a number and a special character'
      return @.render_Page @.jade_password_reset_fail, {errorMessage: 'Your password should be at least 8 characters long. It should have one uppercase and one lowercase letter, a number and a special character'}

    #request options
    options = {
                   method: 'post'
                   body  : {userName: username,token: token, newPassword:@.req.body.password}
                   json  : true
                   url   : @.url_WS_PasswordReset
              }
    request options, (error, response)=>
      if (not error) and response.statusCode is 200
        if response?.body?.d
          @.okMessage = 'Password has been reset'
          @res.redirect(@.url_password_reset_ok )
        else
          @.errorMessage ='Invalid token, perhaps it has expired'
          @.render_Page @.jade_password_reset_fail,{errorMessage: 'Invalid token, perhaps it has expired'}
      else
        @.errorMessage= "TEAM Mentor is unavailable"
        @res.redirect(@.url_error_page)

  render_Page: (jade_Page,params)=>
    @.res.send @.jade_Service.render_Jade_File jade_Page, params



  routes:  ()=>
    using new Router(), ->
      @.post '/user/pwd_reset'                       , (req, res)-> new Pwd_Reset_Controller(req,res).password_Reset()
      @.post '/passwordReset/:username/:token'       , (req, res)-> new Pwd_Reset_Controller(req,res).password_Reset_Token()
      @.get  '/passwordReset/:username/:token'       , (req, res)-> new Pwd_Reset_Controller(req,res).password_Reset_Page()
      @.post '/json/passwordReset/:username/:token'  , (req, res)-> new Pwd_Reset_Controller(req,res).json_Mode().password_Reset_Token()
      @.post '/json/user/pwd_reset'                  , (req, res)-> new Pwd_Reset_Controller(req,res).json_Mode().password_Reset()

module.exports = Pwd_Reset_Controller