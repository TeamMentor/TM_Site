
add_Routes = (express_Service)->
    Jade_Service            = require '../services/Jade-Service'
    Ga_Service              = require '../services/Analytics-Service'
    Article_Controller      = require '../controllers/Article-Controller'
    Flare_Controller        = require '../controllers/Flare-Controller'
    Help_Controller         = require '../controllers/Help-Controller'
    Jade_Controller         = require '../controllers/Jade-Controller'
    Login_Controller        = require '../controllers/Login-Controller'
    Misc_Controller         = require '../controllers/Misc-Controller'
    Search_Controller       = require '../controllers/Search-Controller'
    Pwd_Reset_Controller    = require '../controllers/Pwd-Reset-Controller'
    User_Sign_Up_Controller = require '../controllers/User-Sign-Up-Controller'
    PoC_Controller          = require '../poc/PoC-Controller'

    app                     = express_Service.app
    jade_Service            = new Jade_Service()

    # Log/track request
    app.use (req,res,next)->
      logger?.info {url: req.url , ip: req.connection.remoteAddress,  agent: req.headers.agent }
      using new Ga_Service(req,res),->
        @.track()
      next()

    #run custom code hook (if available)
    global.custom?.express_Routes?(app, require('express'))


    app.get  '/user/login'     , (req, res)-> new Login_Controller(req, res).redirectToLoginPage()
    app.post '/user/login'     , (req, res)-> new Login_Controller(req, res).loginUser()
    app.get  '/user/logout'    , (req, res)-> new Login_Controller(req, res).logoutUser()
    app.post '/user/sign-up'   , (req, res)-> new User_Sign_Up_Controller(req, res).userSignUp();

    app.get '/_Customizations/SSO.aspx', (req, res)-> new Login_Controller(req, res).tm_SSO()
    app.get '/Aspx_Pages/SSO.aspx'     , (req, res)-> new Login_Controller(req, res).tm_SSO()

    app.get '/index.html'      , (req, res)-> res.send jade_Service.render_Jade_File 'guest/default.jade'
    app.get '/guest/:page.html', (req, res)-> res.send jade_Service.render_Jade_File 'guest/' + req.params.page + '.jade'
    app.get '/guest/:page'     , (req, res)-> res.send jade_Service.render_Jade_File 'guest/' + req.params.page + '.jade'
    app.get '/teamMentor'      , (req, res)->
        if req.session?.username
            res.redirect "/user/main.html"                                                                        # to prevent cached infinite redirects (due to 3.5 redirect of / to /teammentor
        else
            res.redirect "/index.html"

    options = { express_Service: express_Service }

    Search_Controller                  .register_Routes(app, express_Service)
    Article_Controller                 .register_Routes(app, express_Service)
    Flare_Controller                   .register_Routes(app                  )
    Pwd_Reset_Controller               .register_Routes(app                  )
    Help_Controller                    .register_Routes(app                  )
    Misc_Controller                    .register_Routes(app                  )
    Jade_Controller                    .register_Routes(app                  )

    new PoC_Controller(options)        .register_Routes()

    #errors 404 and 500
    app.get '/error', (req,res)-> res.status(500).send  jade_Service.render_Jade_File 'guest/500.jade',{ loggedIn:req.session?.username isnt undefined }
    app.get '/*'    , (req,res)-> res.status(404).send  jade_Service.render_Jade_File 'guest/404.jade',{ loggedIn:req.session?.username isnt undefined }

    app.use (err, req, res, next)->
      #console.error(err.stack)
      console.log "Error with request url: #{req.url} \n
                      #{err.stack.split_Lines().take(8).join('\n')}"
      #console.error(err)
      res.status(501)
         .redirect('/error')

module.exports = add_Routes