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
    Hubspot_Service      = require('../services/Hubspot-Service.coffee')
    Jade_Service         = require('../services/Jade-Service')

  constructor: (req, res, options)->
    @.dependencies()
    @.options            = options || {}
    @.req                = req || {}
    @.res                = res || {}

    @.webServices             = @.options.webServices || global.config?.tm_design?.webServices
    @.login                   = new Login_Controller(req,res)
    @.analyticsService        = new Analytics_Service(@.req, @.res)
    @.hubspotService          = new Hubspot_Service(@.req,@.res)
    @.jade_Service            = new Jade_Service()
  userSignUp: ()=>
    userViewModel =
                    {
                        username        : @.req.body.username,
                        password        : @.req.body.password,
                        confirmpassword : @.req.body['confirm-password']
                        email           : @.req.body.email
                        firstname       : @.req.body.firstName,
                        lastname        : @.req.body.lastName,
                        company         : @.req.body.company,
                        title           : @.req.body.title,
                        country         : @.req.body.country,
                        state           : @.req.body.state
                        errorMessage    :''
                    }

    if (@.req.body.password != @.req.body['confirm-password'])
        userViewModel.errorMessage = 'Passwords don\'t match'
        @.render_Page signUp_fail,viewModel: userViewModel
        return

    newUser =
              {
                  username  : @.req.body.username,
                  password  : @.req.body.password,
                  email     : @.req.body.email,
                  firstname : @.req.body.firstName,
                  lastname  : @.req.body.lastName,
                  company   : @.req.body.company,
                  title     : @.req.body.title,
                  country   : @.req.body.country,
                  state     : @.req.body.state
              }
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
        @.analyticsService.track('','User Account',"Signup Success #{@.req.body.username}")
        @.hubspotService.submitHubspotForm()
        return @.login.loginUser()
      if (signUpResponse.Validation_Results.empty())
        message = signUpResponse.Simple_Error_Message || 'An error occurred'
      else
        message = signUpResponse.Validation_Results.first().Message
      userViewModel.errorMessage = message
      @.analyticsService.track('','User Account',"Signup Failed #{@.req.body.username}")
      @.render_Page signUp_fail, {viewModel:userViewModel}

  render_Page: (jade_Page,params)=>
    @.res.send @.jade_Service.render_Jade_File jade_Page, params

  loadSecretFile:() ->
    if (process.cwd().path_Combine('../../config/SiteData_TM/secrets.json').file_Exists())
      secrets = process.cwd().path_Combine('../../config/SiteData_TM/secrets.json').load_Json()
      return secrets
    else
      return ''
module.exports = User_Sign_Up_Controller