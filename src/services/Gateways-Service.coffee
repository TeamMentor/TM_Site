fs                 = null
path               = null
request            = null
Cache_Service      = null
options            = null
search_Controller  = null
article_Controller = null
async              = require 'async'
class Gateways_Service
  dependencies: ->
    fs                 = require('fs')
    path               = require('path')
    request            = require('request')
    Cache_Service      = require('teammentor').Cache_Service
    search_Controller  = require '../controllers/Search-Controller.coffee'
    article_Controller = require '../controllers/Article-Controller.coffee'
    {options}          = require '../config'

  constructor:(req, res) ->
    @.dependencies()
    @.req        = req
    @.res        = res
    @.cache      = new Cache_Service("docs_cache")


  getGatewaysStructure:(callback) =>
    Library = {}
    using new search_Controller(@.req,@.res),->
      @.show_Gateways (data)->
        Library.title = data.title
        Library.Views = []
        for row in data.containers
          view = {}
          view.id       = row.id
          view.title    = row.title
          view.Articles = []
          for articleId in row.articles
            for result in data.results
              if (result.id == articleId)
                article = {id: result.id, guid: result.guid, title: result.title,summary: result.summary}
                view.Articles.push(article)
                break
          Library.Views.push(view)
        callback Library


module.exports = Gateways_Service