
add_Routes = (express_Service)->
    Jade_Service            = require '../services/Jade-Service'
    Ga_Service              = require '../services/Analytics-Service'
    Angular_Controller      = require '../controllers/Angular-Controller'
    API_Controller          = require '../controllers/API-Controller'
    Article_Controller      = require '../controllers/Article-Controller'
    Browser_Controller      = require '../controllers/Browser-Controller'
    Flare_Controller        = require '../controllers/Flare-Controller'
    Help_Controller         = require '../controllers/Help-Controller'
    Gateways_Controller     = require '../controllers/Gateways-Controller'
    Jade_Controller         = require '../controllers/Jade-Controller'
    Login_Controller        = require '../controllers/Login-Controller'
    Misc_Controller         = require '../controllers/Misc-Controller'
    Search_Controller       = require '../controllers/Search-Controller'
    Pwd_Reset_Controller    = require '../controllers/Pwd-Reset-Controller'
    User_Sign_Up_Controller = require '../controllers/User-Sign-Up-Controller'
    PoC_Controller          = require '../poc/PoC-Controller'
    app                     = express_Service.app
    jade_Service            = new Jade_Service()
    uuid                    = require 'uuid'
    # Log/track request
    app.use (req,res,next)->
      logger?.info {url: req.url , ip: req.connection.remoteAddress,  agent: req.headers.agent }
      using new Ga_Service(req,res),->
        if (req.url.starts_With('jade') || req.url.match '/angular/guest/')
            @.track()
        if not req.session.username? && global.config?.tm_security?.Show_ContentToAnonymousUsers
            req.session.username = uuid.v4()  #Setting a surrogate username, since anonymous access is enabled.
        next()

    #run custom code hook (if available)
    global.custom?.express_Routes?(app, require('express')) # todo: needs refactoring

    app.use new API_Controller().routes()

    app.use '/angular',new Angular_Controller().routes()

    app.use '/flare', new Flare_Controller().routes()

    app.use '/'     , new Login_Controller().routes_Json()
    app.use '/'     , new Login_Controller().routes_SSO()

    app.use '/jade', new Login_Controller(    ).routes_Jade()
    app.use '/jade', new Jade_Service(        ).routes()
    app.use '/jade', new Help_Controller(     ).routes()
    app.use '/jade', new Gateways_Controller( ).routes(express_Service)
    app.use '/jade', new Pwd_Reset_Controller().routes()
    app.use '/jade', new Article_Controller(  ).routes(express_Service)
    app.use '/jade', new Search_Controller(   ).routes(express_Service)
    app.use '/jade', new Misc_Controller(     ).routes(express_Service)

    app.use '/'    , new Browser_Controller(  ).routes()

    app.get '/teamMentor'               , (req, res)->
      res.redirect "/browser-detect"
#        if req.session?.username
#            res.redirect "/jade/user/main.html"                                                                        # to prevent cached infinite redirects (due to 3.5 redirect of / to /teammentor
#        else
#            res.redirect "/jade/index.html"

    app.get '/', (req,res)-> res.redirect '/jade/index.html'

    #Help_Controller                    .register_Routes(app                  )
    #Misc_Controller                    .register_Routes(app, express_Service )
    Jade_Controller                    .register_Routes(app                  )

    options = { express_Service: express_Service }
    new PoC_Controller(options)        .register_Routes()

    hideLogout        = global.config?.tm_security?.Show_ContentToAnonymousUsers || @.req?.session?.ssoUser isnt undefined
    #errors 404 and 500
    app.get '/jade/error', (req,res)-> res.status(500).send  jade_Service.render_Jade_File 'guest/500.jade',{ loggedIn:req.session?.username isnt undefined , hideLogout: hideLogout}
    app.get '/*'         , (req,res)-> res.status(404).send  jade_Service.render_Jade_File 'guest/404.jade',{ loggedIn:req.session?.username isnt undefined , hideLogout: hideLogout}

    app.use (err, req, res, next)->
      #console.error(err.stack)
      console.log "Error with request url: #{req.url} \n
                      #{err.stack.split_Lines().take(8).join('\n')}"
      #console.error(err)
      res.status(501)
         .redirect('/error')

module.exports = add_Routes