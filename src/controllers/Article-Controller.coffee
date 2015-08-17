Express_Service   = null
Jade_Service      = null
Graph_Service     = null
Analytics_Service = null
Session_Service   = null

Anonymous_Service = require('../services/Anonymous-Service')
config            = require('../config')
async             = require 'async'

class Article_Controller

  dependencies: ()->
    Express_Service    = require('../services/Express-Service')
    Jade_Service       = require('../services/Jade-Service')
    Graph_Service      = require('../services/Graph-Service')
    Analytics_Service  = require('../services/Analytics-Service')
    Session_Service    = require('../services/Session-Service')

  constructor: (req, res, next,expressService,graph_Options)->
    @.dependencies()
    @.req              = req
    @.res              = res
    @.config           = require '../config'
    @.next             = next
    @.jade_Article     = 'user/article.jade'
    @.jade_Articles    = 'user/articles.jade'
    @.jade_No_Article  = 'user/no-article.jade'
    @.jade_Service     = new Jade_Service();
    @.graphService     = new Graph_Service(graph_Options)
    @.sessionservice   = new Session_Service()
    @.express_Service  =  expressService

  article: =>
    send_Article = (view_Model)=>
      articleUrl = @.req.protocol + '://' + @.req.get('host') + @.req.originalUrl;
      if view_Model
        view_Model.loggedIn          = @.req.session?.username isnt undefined
        view_Model.welcomeMessage    = @.config?.options?.anonymousService?.welcomeMessage.replace '{# articles}', @.req.session.articlesAllowed
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

  recentArticles: =>
    @.req.session ?= {}
    @.req.session.recent_Articles ?= []
    recentArticles = []
    for recentArticle in @.req.session.recent_Articles.take(3)
        recentArticles.push({href : "/article/#{recentArticle.id}" , title:recentArticle.title})
    recentArticles

  recentArticlesJson: =>
    articles = @.req.session?.recent_Articles?.take(3)
    recentArticles = []
    return @.res.json {} if not articles

    async.forEach articles, ((article, callback) =>
      id = article.id.remove('article-')
      @.find_Article_ByRef id, (data)->
        recentArticles.push(data)
        callback()
    ),(done)=>
      return @.res.json recentArticles

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

  recentArticles_Add: (id, title)=>

    logger?.info {user: @.req.session?.username, action:'view-article', id: id  , title: title}

    @.req.session.recent_Articles ?= []
    @.req.session.recent_Articles.unshift { id: id , title:title}

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
          new Analytics_Service(@.req, @.res).track(article_Data?.title,article_Id)
          title      = article_Data?.title
          technology = article_Data?.technology
          type       = article_Data?.type
          phase      = article_Data?.phase
          summary    = article_Data?.summary

          @graphService.article_Html article_Id, (data)=>
            @recentArticles_Add article_Id, title
            callback { id : article_Id, title: title,  summary: summary, article_Html: data?.html, technology: technology, type: type, phase: phase}
      else
        callback null

Article_Controller.register_Routes = (app, expressService,graph_Options) ->

  checkAuth_AnonymousUser        =  (req,res,next)=>
    using new Anonymous_Service(req,res),->
      @.checkAuth next

  checkAuth       =  (req,res,next) -> expressService.checkAuth(req, res, next)
  articleController = (method_Name) ->                                                       # pins method_Name value
        return (req, res,next) ->                                                            # returns function for express
            new Article_Controller(req, res, next,expressService,graph_Options)[method_Name]()   # creates SearchController object with live

  app.get '/a/:ref'               , checkAuth_AnonymousUser, articleController('article')
  app.get '/article/:ref/:guid'   , articleController('check_Guid')
  app.get '/article/:ref/:title'  , checkAuth_AnonymousUser, articleController('article')
  app.get '/article/:ref'         , checkAuth_AnonymousUser, articleController('article')
  app.get '/articles'             , checkAuth_AnonymousUser, articleController('articles')
  app.get '/teamMentor/open/:guid', articleController('check_Guid')
  app.get '/json/article/:ref'    , checkAuth_AnonymousUser, articleController('article_Json')
  app.get '/json/recentarticles'  , checkAuth, articleController('recentArticlesJson')
  app.get '/json/toparticles'     , checkAuth, articleController('topArticlesJson')



module.exports = Article_Controller