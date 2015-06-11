Analytics_Service = require('./../../src/services/Analytics-Service')
expect                  = require("chai").expect
assert                  = require("chai").assert

describe '| services | Analytics-Service.test |', ->

  ga_Service = null

  before ->
    ga_Service = new Analytics_Service()

  it 'constructor()',->
    using new Analytics_Service(), ->
      @.analitycsTrackUrl      = 'http://foo/bar'
      @.analitycsSiteId        = 1
      @.analitycsTrackingSite  = 'http://foo/bar'
      @.setup()


  it ' setup missing Analytics siteId()',->
    using new Analytics_Service(), ->
      @.analitycsEnabled = true
      @.analitycsTrackUrl      = 'http://foo/bar'
      result = @.setup()
      result.toString().assert_Is('Error: siteId must be provided.')

  it ' missing Analytics Track site()',->
    using new Analytics_Service(), ->
      @.analitycsEnabled = true
      @.analitycsSiteId  = 1
      result = @.setup()
      result.toString().assert_Is('Error: A tracker URL must be provided, e.g. http://example.com/piwik.php')

  it 'Track Url', ->
    using new Analytics_Service(),->
      url = 'http://foo/bar'
      @.trackUrl(url)

  it 'Get remote IP (from XFF header)', ->
    req =
      headers:{'x-forwarded-for':'127.0.0.1'}
      session: recent_Articles: []
    res ={}

    using new Analytics_Service(req, res),->
      url = 'http://foo/bar'
      ip = @.remoteIp()
      ip.assert_Is('127.0.0.1')

  it 'Get remote IP (from request )', ->
    req =
      headers:{}
      connection: {'remoteAddress' : '127.0.0.1'}
      session: recent_Articles: []
    res ={}

    using new Analytics_Service(req, res),->
      url = 'http://foo/bar'
      ip = @.remoteIp()
      ip.assert_Is('127.0.0.1')


  it 'Track Url', ->
    req =
      headers       :{'User-Agent':'firefox','Accept-Language':'en-US'}
      url           :'http://foo/bar'
      sessionID     : 'XYZ'
      connection    : {'remoteAddress' : '127.0.0.1'}
      session       : recent_Articles: []
    res ={}
    using new Analytics_Service(req, res),->
      @.analitycsEnabled = true
      @.track('Page Title','Event Category', 'Event Name')
