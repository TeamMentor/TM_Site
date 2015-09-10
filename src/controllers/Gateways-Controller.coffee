fs                 = null
request            = null
Router             = null
Jade_Service       = null
Gateways_Service   = null
content_cache = {};

class Gateways_Controller

  dependencies: ->
    fs                 = require 'fs'
    request            = require 'request'
    {Router}           = require 'express'
    Jade_Service       = require '../services/Jade-Service'
    Gateways_Service   = require '../services/Gateways-Service'

  constructor: (req, res)->
    @.dependencies()
    @.pageParams       = {}
    @.req              = req
    @.res              = res
    @.config           = require '../config'


  json_Gateways_Library: () =>
    using new Gateways_Service(@.req, @.res),->
      @.getGatewaysStructure (callback)=>
        @.res.json callback

  routes: ()=>
    using new Router(), ->
      @.get '/json/gateways/library'    , (req, res)-> new Gateways_Controller(req, res).json_Gateways_Library()
      @.get '/json/gateways/:article'   , (req, res)-> new Gateways_Controller(req, res).json_Docs_Page()

module.exports = Gateways_Controller