signUp_fail             = 'guest/sign-up-Fail.jade'
signUpPage_Unavailable  = 'guest/sign-up-cant-connect.jade'
signUp_Ok               = 'guest/sign-up-OK.html'
errorMessage            = "TEAM Mentor is unavailable, please contact us at "
request                 = null
Config                  = null
Analytics_Service       = null
Hubspot_Service         = null
Jade_Service            = null
Login_Controller        = null
request                 = null
request                 = null

class User_Sign_Up_Controller

  dependencies: ->
    request = require('request')
    Login_Controller     = require('../controllers/Login-Controller')
    Analytics_Service    = require('../services/Analytics-Service')
    Hubspot_Service      = require('../services/Hubspot-Service')
    Jade_Service         = require('../services/Jade-Service')

  constructor: (req, res, options)->
    @.dependencies()
    @.options            = options || {}
    @.req                = req || {}
    @.res                = res || {}

    @.webServices             = @.options.webServices ||"#{global.config?.tm_design?.tm_35_Server}#{global.config?.tm_design?.webServices}"
    @.login                   = new Login_Controller(req,res)
    @.analyticsService        = new Analytics_Service(@.req, @.res)
    @.hubspotService          = new Hubspot_Service(@.req,@.res)
    @.jade_Service            = new Jade_Service()

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

  userSignUp: ()=>
    userViewModel =
                    {
                        username        : @.req.body.username,
                        password        : @.req.body.password,
                        confirmpassword : @.req.body['confirm-password']
                        email           : @.req.body.email
                        firstname       : @.req.body.firstname,
                        lastname        : @.req.body.lastname,
                        company         : @.req.body.company,
                        title           : @.req.body.title,
                        country         : @.req.body.country,
                        state           : @.req.body.state
                        errorMessage    :''
                    }
    newUser =
              {
                  username  : @.req.body.username,
                  password  : @.req.body.password,
                  email     : @.req.body.email,
                  firstname : @.req.body.firstname,
                  lastname  : @.req.body.lastname,
                  company   : @.req.body.company,
                  title     : @.req.body.title,
                  country   : @.req.body.country,
                  state     : @.req.body.state
              }

    if(@.req.body.username is undefined or @.req.body.username =='')
      userViewModel.errorMessage = 'Username is a required field.'
      return @.render_Page signUp_fail,viewModel: userViewModel

    if(@.req.body.password is undefined or @.req.body.password =='')
      userViewModel.errorMessage = 'Password is a required field.'
      return @.render_Page signUp_fail,viewModel: userViewModel

    if(@.req.body['confirm-password'] is undefined or @.req.body['confirm-password'] =='')
      userViewModel.errorMessage = 'Confirm password is a required field.'
      return @.render_Page signUp_fail,viewModel: userViewModel

    if (@.req.body.password != @.req.body['confirm-password'])
      userViewModel.errorMessage = 'Passwords don\'t match'
      return @.render_Page signUp_fail,viewModel: userViewModel

    if(@.req.body.email is undefined or @.req.body.email =='')
      userViewModel.errorMessage = 'Email is a required field.'
      return @.render_Page signUp_fail,viewModel: userViewModel

    if(@.req.body.firstname is undefined or @.req.body.firstname =='')
      userViewModel.errorMessage = 'First Name is a required field.'
      return @.render_Page signUp_fail,viewModel: userViewModel

    if(@.req.body.lastname is undefined or @.req.body.lastname =='')
      userViewModel.errorMessage = 'Last Name is a required field.'
      return @.render_Page signUp_fail,viewModel: userViewModel
      
      
    if(@.req.body.country is undefined or @.req.body.country =='')
      userViewModel.errorMessage = 'Country is a required field.'
      return @.render_Page signUp_fail,viewModel: userViewModel
      

    options = {
                method: 'post',
                body: {newUser: newUser},
                json: true,
                url: @.webServices + '/CreateUser_Response'
              };

    request options, (error, response, body)=>
      if (error and error.code is "ENOTFOUND")
        #[QA] ADD ISSUE: Refactor this to show TM 500 error message
        logger?.info ('Could not connect with TM 3.5 server')
        userViewModel.errorMessage =errorMessage
        return @.render_Page signUpPage_Unavailable, {viewModel:userViewModel}

      if (error or response.body is null or response.statusCode isnt 200)
        logger?.info ('Bad response received from TM 3.5 server')
        userViewModel.errorMessage =errorMessage
        return @.render_Page signUpPage_Unavailable, {viewModel:userViewModel}


      signUpResponse = response.body?.d

      if (not signUpResponse) or (not signUpResponse.Validation_Results)
        logger?.info ('Bad data received from TM 3.5 server')
        return @.render_Page signUpPage_Unavailable, {viewModel: errorMessage : 'An error occurred' }

      message = ''
      if (signUpResponse.Signup_Status is 0)
        @.analyticsService.track('Signup','User Account',"Signup Success #{@.req.body.username}")
        @.hubspotService.submitHubspotForm()
        return @.login.loginUser()
      if (signUpResponse.Validation_Results.empty())
        message = signUpResponse.Simple_Error_Message || 'An error occurred'
      else
        message = signUpResponse.Validation_Results.first().Message
      userViewModel.errorMessage = message
      @.analyticsService.track('Signup','User Account',"Signup Failed #{@.req.body.username}")
      @.render_Page signUp_fail, {viewModel:userViewModel}

  render_Page: (jade_Page,params)=>
    @.res.send @.jade_Service.render_Jade_File jade_Page, params

module.exports = User_Sign_Up_Controller