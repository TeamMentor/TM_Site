request                 = null

class Hubspot_Service
  dependencies: ->
    request = require('request')

  constructor:(req,res)->
    @.dependencies()
    @.req = req
    @.res = res
    @.HubspotEnabled           = global.config?.hubspot?.HubspotEnabled
    @.HubspotEndpoint          = global.config?.hubspot?.HubspotEndpoint
    @.HubspotLeadSource        = global.config?.hubspot?.HubspotLeadSource
    @.HubspotLeadSourceDetail  = global.config?.hubspot?.HubspotLeadSourceDetail
    @.HubspotSecrets           = global.config?.hubspot?.secrets

  setup:() =>
    if @.HubspotEnabled
      'Hubspot is enabled'.log()
      if not @.HubspotEndpoint
        'Error: Hubspot endpoint is not configured..'.log()
      else if not @.HubspotLeadSource
        'Error:Hubspot TEAMMentor Lead Source not configured.'
      else if not @.HubspotLeadSourceDetail
        'Error:Hubspot TEAMMentor Lead Source Details not configured.'
      else if not @.HubspotSecrets
        'Error: You need to configure Hubspot secrets.'.log()
    else
      'Hubspot not enabled'.log()

  submitHubspotForm:() ->
    if not @.HubspotEnabled
      return;
    if not @.HubspotSecrets
      return;

    secret = @.HubspotSecrets
    if(secret?.HubspotSiteId && secret?.HubspotFormGuid)
      siteId      = secret.HubspotSiteId
      formguid    = secret?.HubspotFormGuid
      baseUrl     = @.HubspotEndpoint
      postUrl     = "#{baseUrl}#{siteId}/#{formguid}"
      options = {
        method: 'post',
        form:{
          firstname             :@.req.body.firstname,
          lastname              :@.req.body.lastname,
          email                 :@.req.body.email,
          company               :@.req.body.company,
          title                 :@.req.body.title,
          country               :@.req.body.country,
          state__c              :@.req.body.state,
          leadsource            :@.HubspotLeadSource,
          lead_source_detail__c :@.HubspotLeadSourceDetail
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        url: postUrl
      };
      request options, (error, response)=>
        if(error  or response?.statusCode isnt 204)
          logger?.info ('Hubspot submit error ' + error)
        else
          logger?.info ('Information sent to Hubspot')
    else
      logger?.info ('Hubspot is enabled but secret data is not configured.')


  module.exports =Hubspot_Service