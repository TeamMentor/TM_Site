Router            = null
Express_Service   = null
Jade_Service      = null
Graph_Service     = null
Analytics_Service = null
Session_Service   = null
Browser_Controller=null

Anonymous_Service = require('../services/Anonymous-Service')
config            = require('../config')
async             = require 'async'

class Article_Controller

  dependencies: ()->
    {Router}           = require 'express'
    Express_Service    = require('../services/Express-Service')
    Jade_Service       = require('../services/Jade-Service')
    Graph_Service      = require('../services/Graph-Service')
    Analytics_Service  = require('../services/Analytics-Service')
    Session_Service    = require('../services/Session-Service')
    Browser_Controller = require('../controllers/Browser-Controller.coffee')

  constructor: (req, res, next,expressService,graph_Options)->
    @.dependencies()
    @.req                    = req
    @.res                    = res
    @.config                 = require '../config'
    @.next                   = next
    @.jade_Article           = 'user/article.jade'
    @.jade_Articles          = 'user/articles.jade'
    @.jade_No_Article        = 'user/no-article.jade'
    @.jade_Service           = new Jade_Service();
    @.graphService           = new Graph_Service(graph_Options)
    @.browserController      = new Browser_Controller()
    @.sessionservice         = new Session_Service()
    @.express_Service        =  expressService
    @.virtualArticlesEnabled = global.config?.virtualArticles?.AutoRedirectIfGuidNotFound
    @.virtualArticlesTarget  = global.config?.virtualArticles?.AutoRedirectTarget


  article: =>
    send_Article = (view_Model)=>
      articleUrl = @.req.protocol + '://' + @.req.get('host') + @.req.originalUrl;
      if view_Model
        view_Model.loggedIn          = @.req.session?.username isnt undefined
        view_Model.hideLogout        = @.config?.options?.tm_security?.Show_ContentToAnonymousUsers || @.req?.session?.ssoUser isnt undefined
        view_Model.signUpUrl         = @.config?.options?.anonymousService?.signUpUrl
        view_Model.loginUrl          = @.config?.options?.anonymousService?.loginUrl
        #recentArticles = @.recentArticles()
        #console.log "recent articles are: " + recentArticles
        #console.log "Article is: " + articleUrl
        if @.req.session?.articlesAllowed >= 1
          mapWelcomeMsg = {
            articles:         @.req.session?.articlesAllowed,
            totalAllowed:     @.config?.options?.anonymousService?.allowedArticles,
          }
          re = new RegExp(Object.keys(mapWelcomeMsg).join("|"),"gi")
          #console.log "re is: " + re
          view_Model.welcomeMessage    = @.config?.options?.anonymousService?.welcomeMessage.replace re, (matched)-> return mapWelcomeMsg[matched]
        else
          view_Model.welcomeMessage   = @.config?.options?.anonymousService?.noArticleCredits
        view_Model.internalUser      = @.req.session?.internalUser
        view_Model.githubUrl         = @.config?.options?.tm_design.githubUrl
        view_Model.githubContentUrl  = @.config?.options?.tm_design.githubContentUrl
        view_Model.supportEmail      = @.config?.options?.tm_design.supportEmail
        view_Model.articleUrl        = articleUrl
        @res.send @jade_Service.render_Jade_File(@.jade_Article, view_Model)
      else
        @res.send @.jade_Service.render_Jade_File(@.jade_No_Article)

    @.resolve_Article_Ref @req.params.ref, send_Article

  article_Json: =>
    @.resolve_Article_Ref @req.params.ref, (view_Model)=>
      @.res.json view_Model

  articles: =>
    @graphService.articles (articles)=>
      view_Model = { results: articles.values()}
      @res.send @jade_Service.render_Jade_File(@jade_Articles, view_Model)

  check_Guid: =>
    guid = @.req.params?.guid
    if(guid and                                                                       # if we have a value
       guid.split('-').size() is 5 and                                                #   are there are 4 dashes
       guid.size() is 36)                                                             #   and the size if 32
      guid_regex = /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/i  # use this regex to check if the value provided is a guid
      if guid_regex.test(guid.upper())                                                # if it isa regex
        return @.res.redirect "/article/#{guid}"                                      #   redirect the user back to the /article/:ref route
                                                                                      # if not
    @.next()                                                                          #   continue with the next express route

  my_Articles: =>
    results = {}
    size = @.req.params?.size

    for item in @.req.session.recent_Articles
      #results[item.id] ?= { href: "/article/#{item.id}", title: item.title, weight: 0}
      #if item.technology
      results[item.id] ?= { id: item.id, title: item.title, technology: item.technology, phase: item.phase, type:item.type, weight: 0}
      results[item.id].weight++

    results = (results[key] for key in results.keys())

    results = results.sort (a,b)-> a.weight - b.weight
    results.reverse()

    size = parseInt(size,10)

    if is_Number(size)
      results = results.take(size)

    if @.req.query['pretty'] is ''                              # if a ?pretty to the request url (show a formatted version of the data)
      @.res.send "<pre>" + results?.json_Pretty() + "</pre>"     #   send the data wrapped in a <pre> tag so that it shows ok in a browser
    else
      @.res.json results

#  recentArticles: =>
#    @.req.session ?= {}
#    @.req.session.recent_Articles ?= []
#    recentArticles = []
#    for recentArticle in @.req.session.recent_Articles.take(3)
#        recentArticles.push({href : "/article/#{recentArticle.id}" , title:recentArticle.title})
#    recentArticles

  recentArticlesJson: =>
    size = parseInt(@.req.params?.size, 10)
    if is_Number(size)
      articles = {}
      for article in @.req.session.recent_Articles
        if article.when
          articles[article.id] = article

      results = (value for key,value of articles)
      #results = results.sort (a,b)-> a.when - b.when
      results = results.take(size)

      if @.req.query['pretty'] is ''                               # if a ?pretty to the request url (show a formatted version of the data)
        @.res.send "<pre>" + results?.json_Pretty() + "</pre>"     #   send the data wrapped in a <pre> tag so that it shows ok in a browser
      else
        @.res.json results
    else
      @.res.json []

#
#    async.forEach articles, ((article, callback) =>
#      id = article.id.remove('article-')
#      @.find_Article_ByRef id, (data)->
#        recentArticles.push(data)
#        callback()
#    ),(done)=>
#      return @.res.json recentArticles

  topArticlesJson: =>
    topArticles = []
    @.express_Service.session_Service.top_Articles (data)=>
      if data
        async.forEach data.take(3), ((article, callback) =>
          id = article.href.split('/')[2].remove('article-')
          @.find_Article_ByRef id, (data)->
            topArticles.push(data)
            callback()
        ),(done)=>
          return @.res.json topArticles
      else
        return []

  recentArticles_Add: (id, title, technology , type, phase )=>
    logger?.info {user: @.req.session?.username, action:'view-article', id: id  , title: title}
    @.req.session.recent_Articles ?= []
    log_Data =
      id         : id
      title      : title
      technology : technology
      type       : type
      phase      : phase
      when       : (new Date()).getTime()
    @.req.session.recent_Articles.unshift log_Data

  find_Article_ByRef: (article_Ref, callback)=>
    @.graphService.article article_Ref, (data)=>
      article_Id = data.article_Id
      if article_Id
        @graphService.node_Data article_Id, (article_Data)=>
          title      = article_Data?.title
          technology = article_Data?.technology
          type       = article_Data?.type
          phase      = article_Data?.phase
          summary    = article_Data?.summary

          @graphService.article_Html article_Id, (data)=>
            callback { id : article_Id, title: title,  summary: summary, article_Html: data?.html, technology: technology, type: type, phase: phase}
      else
        callback null

  resolve_Article_Ref: (article_Ref, callback)=>
    @.graphService.article article_Ref, (data)=>
      article_Id = data.article_Id
      if article_Id
        @graphService.node_Data article_Id, (article_Data)=>
          if @.req.session.TPRequest?
            using new Analytics_Service(@.req, @.res),->         #Tracking TP access to articles.
              actionName = article_Data?.title
              category   = 'TEAM Professor View Article'
              eventName  = "Title :" + article_Data?.title + " Id : " +article_Id
              @.track(actionName,category, eventName)
            delete @.req.session.TPRequest                       #Undefining session variable
          else
            using new Analytics_Service(@.req, @.res),->
              @.track(article_Data?.title,"View Article","Title :" + article_Data?.title + " Id : " +article_Id)

          new Analytics_Service(@.req, @.res).track()
          title      = article_Data?.title
          technology = article_Data?.technology
          type       = article_Data?.type
          phase      = article_Data?.phase
          summary    = article_Data?.summary

          @graphService.article_Html article_Id, (data)=>
            @recentArticles_Add article_Id, title, technology , type, phase
            callback { id : article_Id, title: title,  summary: summary, article_Html: data?.html, technology: technology, type: type, phase: phase}
      else
        if (@.virtualArticlesEnabled && @.virtualArticlesTarget?.length >0)
            use_Flare = @.browserController.use_Flare(@.req, @.res)
            if use_Flare
              callback {redirectUrl: @.virtualArticlesTarget + '/article/' + article_Ref}
            else
             @.res.redirect @.virtualArticlesTarget + '/article/' + article_Ref
        else
          new Analytics_Service(@.req, @.res).track("Article Not Found: " + article_Ref,"Article Not Found","Article Not Found")
          callback null

  routes: (expressService) ->

    checkAuth_AnonymousUser        =  (req,res,next)=>
      using new Anonymous_Service(req,res),->
        @.checkAuth next

    checkAuth       = (req,res,next) -> expressService.checkAuth(req, res, next)
    graph_Options   = { express_Service: expressService }

    articleController = (method_Name) ->                                                       # pins method_Name value
      return (req, res,next) ->                                                                # returns function for express
          new Article_Controller(req, res, next,expressService,graph_Options)[method_Name]()   # creates SearchController object with live

    using new Router(),->
      @.get '/a/:ref'                    , checkAuth_AnonymousUser, articleController('article')
      @.get '/article/:ref/:guid'        , articleController('check_Guid')
      @.get '/article/:ref/:title'       , checkAuth_AnonymousUser, articleController('article')
      @.get '/article/:ref'              , checkAuth_AnonymousUser, articleController('article')
      @.get '/articles'                  , checkAuth_AnonymousUser, articleController('articles')
      @.get '/teamMentor/open/:guid'     , articleController('check_Guid')
      @.get '/json/article/:ref'         , checkAuth_AnonymousUser, articleController('article_Json')
      @.get '/json/recentarticles/:size' , checkAuth, articleController('recentArticlesJson')
      @.get '/json/toparticles'          , checkAuth, articleController('topArticlesJson')
      @.get '/json/my-articles/:size'    , checkAuth, articleController('my_Articles')


module.exports = Article_Controller