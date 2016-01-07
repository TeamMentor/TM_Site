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

  routes: (expressService)=>
    checkAuth       = (req,res,next) -> expressService.checkAuth(req, res, next)

    gatewaysController = (method_Name) ->                                                    # pins method_Name value
      return (req, res,next) ->                                                              # returns function for express
        new Gateways_Controller(req, res, next)[method_Name]()                               # Methodname

    using new Router(), ->
      @.get '/json/gateways/library'    ,checkAuth,gatewaysController("json_Gateways_Library")

module.exports = Gateways_Controller