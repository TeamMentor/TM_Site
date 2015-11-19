fs                 = null
path               = null
request            = null
Router             = null
Express_Service    = null
Jade_Service       = null
Graph_Service      = null
Analytics_Service  = null

recentSearches_Cache = ["Logging","Struts","Administrative Controls"]

class SearchController
    constructor: (req, res,express_Service)->

        fs                 = require('fs')
        path               = require('path')
        request            = require('request')
        {Router}           = require 'express'
        Express_Service    = require('../services/Express-Service')
        Jade_Service       = require('../services/Jade-Service')
        Graph_Service      = require('../services/Graph-Service')
        Analytics_Service  = require('../services/Analytics-Service')

        @.req                = req
        @.res                = res
        @.config             = require '../config'
        @.express_Service    = express_Service
        @.jade_Service       = new Jade_Service()
        @.graph_Service      = new Graph_Service()
        @.defaultUser        = 'TMContent'
        @.defaultRepo        = 'TM_Test_GraphData'
        @.defaultFolder      = '/SearchData/'
        @.defaultDataFile    = 'Data_Validation'
        @.searchData         = null

        @.jade_Main               = 'user/main.jade'
        @.jade_Search             = 'user/search.jade'
        @.jade_Error_Page         = 'guest/404.jade'
        @.jade_Search_two_columns = 'user/search-two-columns.jade'
        @.root_Path               = __dirname.path_Combine '../../../../'



    #renderPage: ()->
    #    @jade_Service.render_Jade_File(@jade_Page, @searchData)

    render_Page: (jade_Page,params)=>
      @.res.send @.jade_Service.render_Jade_File jade_Page, params

    get_Navigation: (queryId, callback)=>

      @.graph_Service.resolve_To_Ids queryId, (data)=>
        navigation = []
        path = null
        for key in data.keys()
          item = data[key]
          path = if path then "#{path},#{key}" else "#{key}"
          if item and path
            navigation.push {href:"/jade/show/#{path}", title: item.title , id: item.id }

        callback navigation

    showSearchFromGraph: ()=>
        queryId = @.req.params.queryId
        filters = @.fix_Filters @req.params.filters

        logger?.info {user: @.req.session?.username, action:'show', queryId: queryId, filters:filters}

        if (not queryId?)
          logger?.info {Error:'GraphDB might not be available, please verify.'}

        @get_Navigation queryId, (navigation)=>
          target = navigation.last() || {}
          @graph_Service.graphDataFromGraphDB target.id, filters,  (searchData)=>
            @searchData = searchData
            if not searchData
              return @.render_Page @.jade_Search
              #@res.send(@renderPage())

            searchData.filter_container   = filters
            @searchData.breadcrumbs       = navigation
            @searchData.href              = target.href
            @searchData.internalUser      = @.req.session?.internalUser
            @searchData.githubUrl         = @.config?.options?.tm_design.githubUrl
            @searchData.githubContentUrl  = @.config?.options?.tm_design.githubContentUrl
            @searchData.supportEmail      = @.config?.options?.tm_design.supportEmail

            if filters
              @graph_Service.resolve_To_Ids filters, (results)=>
                @searchData.activeFilter         = results.values()
                @searchData.activeFilter.ids     = (value.id for value in results.values())
                @searchData.activeFilter.titles  = (value.title for value in results.values())
                @searchData.activeFilter.filters = filters
                if (@.searchData.results?)
                  return @.render_Page @.jade_Search, @.searchData
                  #@res.send(@renderPage())
                else
                  logger?.info {Error:'There are no results that match the search.',queryId: queryId, filters:filters}
                  return @.render_Page @.jade_Error_Page,{loggedIn:@.req.session?.username isnt undefined}
            else
              if (@.searchData.results?)
                return @.render_Page @.jade_Search, @.searchData
                #@res.send(@renderPage())

              logger?.info {Error:'There are no results that match the search.',queryId: queryId, filters:filters}
              return @.render_Page  @.jade_Error_Page,{loggedIn:@.req.session?.username isnt undefined}

    search_Via_Url: =>
      @.req.query.text = @.req.params.text
      @.search()

    fix_Filters: (filters)=>
      if filters
        if filters.substring(0,1) is ','
          filters = filters.substring(1)
        if filters.substring(filters.length-1,filters.length) is ','
          filters = filters.substring(0, filters.length-1)
        filters = filters.replace(',,',',')

    show_Gateways: (callback)=>
      query_Id      = 'query-da0f0babaad8'
      jsonPath      = 'data/Lib_UNO-json/Library/UNO.json'
      indexFile     = @.root_Path.path_Combine jsonPath
      library       = indexFile.load_Json()?.guidanceExplorer?.library?.first()
      return callback null if not library?

      for view in library?.libraryStructure?.first()?.folder
        if (view?.$?.caption == 'Guides')
          guides = view
          break
      @graph_Service.graphDataFromGraphDB query_Id, '',  (searchData)=>
        searchData.internalUser      = @.req.session?.internalUser
        searchData.githubUrl         = @.config?.options?.tm_design.githubUrl
        searchData.githubContentUrl  = @.config?.options?.tm_design.githubContentUrl
        searchData.supportEmail      = @.config?.options?.tm_design.supportEmail
        views  = guides?.view

        #Step 1 :Sorting the views
        temp   = []
        for view in views
          for folder in searchData.containers
            if view.$.caption == folder.title
              temp.push (folder)
              break
        searchData.containers = temp

        #Step 2 : Sorting articles
        index  =0
        data   = searchData.containers

        while index < data?.length
          originalArticles = guides?.view[index]?.items?.first()?.item
          counter          = 0
          while counter < originalArticles?.length
            article = 'article-' + originalArticles[counter]?.split('-')?[4] #Formatting article Id
            data[index]?.articles[counter] = article                         #Assigning the id
            counter++
          index++

        searchData.containers = data
        callback searchData

    search: =>
      target  = @.req.query?.text
      filters = @.fix_Filters @.req.query?.filters?.substring(1)

      logger?.info {user: @.req.session?.username, action:'search', target: target, filters:filters}

      new Analytics_Service(@.req, @.res).track("","","",target, "Text Search")

      #jade_Page = 'user/search-two-columns.jade'


      @graph_Service.query_From_Text_Search target,  (query_Id)=>
        query_Id = query_Id?.remove '"'
        @graph_Service.graphDataFromGraphDB query_Id, filters,  (searchData)=>
          if not searchData
            return @.render_Page  @.jade_Search_two_columns, { no_Results : true , text: target}

          searchData.text              =  target
          searchData.href              = "/jade/search?text=#{target?.url_Encode()}&filters="
          searchData.internalUser      = @.req.session?.internalUser
          searchData.githubUrl         = @.config?.options?.tm_design.githubUrl
          searchData.githubContentUrl  = @.config?.options?.tm_design.githubContentUrl
          searchData.supportEmail      = @.config?.options?.tm_design.supportEmail
          @.req.session.user_Searches ?= []
          if searchData?.id
            user_Search = { id: searchData.id, title: searchData.title, results: searchData.results.size(), username: @.req.session.username }
            @.req.session.user_Searches.push user_Search
          else
            @graph_Service.search_Log_Empty_Search @.req.session?.username , target, =>
              searchData.no_Results = true
              @.render_Page @.jade_Search_two_columns, searchData
            return

          if filters
            @graph_Service.resolve_To_Ids filters, (results)=>
              searchData.activeFilter         = results.values()
              searchData.activeFilter.ids     = (value.id for value in results.values())
              searchData.activeFilter.titles  = (value.title for value in results.values())
              searchData.activeFilter.filters = filters
              @.render_Page @.jade_Search_two_columns, searchData
          else
            @.render_Page @.jade_Search_two_columns, searchData

    recent_Search : ()=>
      @.express_Service.session_Service.top_Searches (data)=>
        @.res.json data.take(3)

    show_Root_Query: ()=>
      @.graph_Service.library_Query (data)=>
        @.req.params.queryId = data.queryId
        @.showSearchFromGraph()

    showMainAppView: =>
      @.express_Service.session_Service.user_Data @.req.session, (user_Data)=>
        user_Data.internalUser      = @.req.session?.internalUser
        user_Data.githubUrl         = @.config?.options?.tm_design.githubUrl
        user_Data.githubContentUrl  = @.config?.options?.tm_design.githubContentUrl
        user_Data.supportEmail      = @.config?.options?.tm_design.supportEmail

        @.render_Page @.jade_Main, user_Data

    routes: (expressService) ->

      expressService ?= new Express_Service()
      checkAuth       =  (req,res,next) -> expressService.checkAuth(req, res,next)

      searchController = (method_Name) ->                                  # pins method_Name value
          return (req, res) ->                                             # returns function for express
              new SearchController(req, res,expressService)[method_Name]()    # creates SearchController object with live
                                                                           # res,req and invokes method_Name
      using new Router(),->
        @.get "/"                              , checkAuth , searchController('showMainAppView')
        @.get "/show"                          , checkAuth , searchController('show_Root_Query')
        @.get "/show/:queryId"                 , checkAuth , searchController('showSearchFromGraph')
        @.get "/show/:queryId/:filters"        , checkAuth , searchController('showSearchFromGraph')
        @.get "/user/main.html"                , checkAuth , searchController('showMainAppView')
        @.get "/search"                        , checkAuth,  searchController('search')
        @.get "/search/:text"                  , checkAuth,  searchController('search_Via_Url')
        @.get "/json/search/recentsearch"      , checkAuth,  searchController('recent_Search')
        @.get "/json/search/gateways"          , checkAuth,  searchController('show_Gateways')

module.exports = SearchController