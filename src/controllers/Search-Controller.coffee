fs                 = null
path               = null
request            = null
Express_Service    = null
Jade_Service       = null
Graph_Service      = null


recentSearches_Cache = ["Logging","Struts","Administrative Controls"]
url_Prefix           = 'show'

class SearchController
    constructor: (req, res,express_Service)->

        fs                 = require('fs')
        path               = require('path')
        request            = require('request')
        Express_Service    = require('../services/Express-Service')
        Jade_Service       = require('../services/Jade-Service')
        Graph_Service      = require('../services/Graph-Service')

        @.req                = req
        @.res                = res
        @.express_Service    = express_Service
        @.jade_Service       = new Jade_Service()
        @.graph_Service      = new Graph_Service()
        @.defaultUser        = 'TMContent'
        @.defaultRepo        = 'TM_Test_GraphData'
        @.defaultFolder      = '/SearchData/'
        @.defaultDataFile    = 'Data_Validation'
        @.urlPrefix          = url_Prefix
        @.searchData         = null

        @.jade_Main               = 'user/main.jade'
        @.jade_Search             = 'user/search.jade'
        @.jade_Error_Page         = 'guest/404.jade'
        @.jade_Search_two_columns = 'user/search-two-columns.jade'


    
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
            navigation.push {href:"/#{@urlPrefix}/#{path}", title: item.title , id: item.id }

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

            searchData.filter_container = filters
            @searchData.breadcrumbs = navigation
            @searchData.href = target.href

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


    search: =>
      target  = @.req.query?.text
      filters = @.fix_Filters @.req.query?.filters?.substring(1)

      logger?.info {user: @.req.session?.username, action:'search', target: target, filters:filters}

      #jade_Page = 'user/search-two-columns.jade'


      @graph_Service.query_From_Text_Search target,  (query_Id)=>
        query_Id = query_Id?.remove '"'
        @graph_Service.graphDataFromGraphDB query_Id, filters,  (searchData)=>
          if not searchData
            return @.render_Page  @.jade_Search_two_columns, { no_Results : true , text: target}

          searchData.text         =  target
          searchData.href         = "/search?text=#{target?.url_Encode()}&filters="

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


    show_Root_Query: ()=>
      @.graph_Service.library_Query (data)=>
        @.req.params.queryId = data.queryId
        @.showSearchFromGraph()

    showMainAppView: =>
        @.express_Service.session_Service.user_Data @.req.session, (user_Data)=>
          user_Data.internalUser= @.req.session?.internalUser
          @.render_Page @.jade_Main, user_Data

SearchController.register_Routes = (app, expressService) ->

    expressService ?= new Express_Service()
    checkAuth       =  (req,res,next) -> expressService.checkAuth(req, res,next)
    urlPrefix       = url_Prefix            # urlPrefix should be moved to a global static class

    searchController = (method_Name) ->                                  # pins method_Name value
        return (req, res) ->                                             # returns function for express
            new SearchController(req, res,expressService)[method_Name]()    # creates SearchController object with live
                                                                         # res,req and invokes method_Name

    app.get "/"                              , checkAuth , searchController('showMainAppView')
    app.get "/#{urlPrefix}"                  , checkAuth , searchController('show_Root_Query')
    app.get "/#{urlPrefix}/:queryId"         , checkAuth , searchController('showSearchFromGraph')
    app.get "/#{urlPrefix}/:queryId/:filters", checkAuth , searchController('showSearchFromGraph')
    app.get "/user/main.html"                , checkAuth , searchController('showMainAppView')
    app.get "/search"                        , checkAuth,  searchController('search')
    app.get "/search/:text"                  , checkAuth,  searchController('search_Via_Url')

module.exports = SearchController