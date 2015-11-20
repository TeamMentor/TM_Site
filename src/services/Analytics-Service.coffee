piwikAnalytics   = null
piwik            = null
config           = require '../config'

class Analytics_Service

  dependencies:()->
    piwikAnalytics   = require 'piwik-tracker'

  constructor:(req, res)->
    @.dependencies()
    @.req                   = req
    @.res                   = res
    @.analitycsEnabled      = global.config?.piwikAnalytics?.analitycsEnabled
    @.analitycsSiteId       = global.config?.piwikAnalytics?.analitycsSiteId
    @.analitycsTrackingSite = global.config?.piwikAnalytics?.analitycsTrackingSite
    @.analitycsTrackUrl     = global.config?.piwikAnalytics?.analitycsTrackUrl
    @.apiKey                = global.config?.piwikAnalytics?.secrets?.analyticsApiKey

  setup:() =>
    if @.analitycsEnabled
      'Analytics is enabled'.log()
      if not @.analitycsSiteId
        'Error: siteId must be provided.'.log()
      else if not @.analitycsTrackUrl
        'Error: A tracker URL must be provided, e.g. http://example.com/piwik.php'.log()
      else
        piwik = new piwikAnalytics(@.analitycsSiteId, @.analitycsTrackUrl)
    else
      'Analytics not enabled'.log()

  remoteIp: () ->
    ipAddr = @.req.headers["x-forwarded-for"]
    if (ipAddr)
      ipAddr = @.req.headers['x-forwarded-for'].split(',')[0]
    else
      ipAddr = @.req.connection.remoteAddress
    return ipAddr

  trackUrl: (url) ->
    piwik?.track (url)

  track : (pageTitle,eventCategory, eventName, searchKeyword, searchCategory) ->
    if not @.analitycsEnabled
      return

    uniqueId   = @.req?.session?.userEmail              #Unique Id is user's email
    actionName = if pageTitle? then pageTitle else ''
    url        = @.analitycsTrackingSite + @.req.url
    ipAddress  = @.remoteIp()


    if @.req?.session?.token?                           #The unique visitor ID, must be a 16 characters hexadecimal string
      token             = @.req?.session?.token?.split('-')
      visitorId         = token[3] + token[4]
    else
      visitorId         = @.req.sessionID

    piwik?.track({
      url            :url,
      action_name    :actionName,
      _id            :visitorId,
      rand           :@.req.sessionID.add_5_Random_Letters(),            #random value to avoid caching
      apiv           :1,                                                 #Api version always set to 1
      uid            :uniqueId,
      ua             :@.req.header?("User-Agent"),
      lang           :@.req.header?("Accept-Language"),
      token_auth     :@.apiKey,
      cip            :ipAddress,
      urlref         :@.req.headers?["referer"],                         #referer HTTP header
      e_c            :eventCategory,                                     #Event category
      e_a            :actionName,                                        #Event action
      e_n            :eventName,                                         #Event name
      e_v            :1,                                                 #Event value
      cvar: JSON.stringify({                                             #Extra variableS
        '1': ['API version', 'v1'],
        '2': ['HTTP method', @.req.method]
      }),
      search        : searchKeyword  if searchKeyword?                   #Tracking searches
      search_cat    : searchCategory if searchCategory?                  #Tracking search category
    });

  module.exports =Analytics_Service

