Browser_Controller = require '../../src/controllers/Browser-Controller'

describe '| controllers | Browser-Controller', ->

  chrome_Osx_User_Agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36'
  firefox_Osx_User_Agent  = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:39.0) Gecko/20100101 Firefox/39.0'
  safari_Osx_User_Agent  = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_4) AppleWebKit/600.7.12 (KHTML, like Gecko) Version/8.0.7 Safari/600.7.12'

  it 'constructor', ->
    Browser_Controller.assert_Is_Function()
    using new Browser_Controller(), ->


  it 'routes', ->
    using new Browser_Controller(), ->
      paths = for item in @.routes().stack
        if item.route
          item.route.path
      paths.assert_Is [ '/browser',
                        '/',
                        '/browser-detect',
                        '/article/*',
                        '/search',
                        '/passwordReset/*' ]

  it 'detect', (done)->
    using new Browser_Controller(), ->
      req =
        headers:
          'user-agent' : 'aaaa'
      res =
        send: (data)->
          data.assert_Is 'aaaa'
          done()
      @.detect(req,res)

  it 'is_5_0', ->
    using new Browser_Controller(), ->
      req = headers: 'user-agent': 'MSIE'
      @.is_5_0(req, null).assert_Is_False()

      req = headers: 'user-agent': chrome_Osx_User_Agent
      @.is_5_0(req, null).assert_Is_True()

  it 'is_Chrome', ->
    using new Browser_Controller(), ->
      req = headers: 'user-agent': 'MSIE'
      @.is_Firefox(req, null).assert_Is_False()

      req = headers: 'user-agent': chrome_Osx_User_Agent
      @.is_Chrome(req, null).assert_Is_True()

  it 'is_Firefox', ->
    using new Browser_Controller(), ->
      req = headers: 'user-agent': 'MSIE'
      @.is_Firefox(req, null).assert_Is_False()

      req = headers: 'user-agent': firefox_Osx_User_Agent
      @.is_Firefox(req, null).assert_Is_True()

  it 'is_Safari', ->
    using new Browser_Controller(), ->
      req = headers: 'user-agent': chrome_Osx_User_Agent
      @.is_Safari(req, null).assert_Is_False()

      req = headers: 'user-agent': safari_Osx_User_Agent
      @.is_Safari(req, null).assert_Is_True()


  it 'use_Flare (returns true)', ()->
    using new Browser_Controller(), ->
      req =
        headers:
          'user-agent': chrome_Osx_User_Agent
      res = {}

      @.use_Flare(req,res).assert_Is_True()

  it 'use_Flare (returns true)', ()->
    using new Browser_Controller(), ->
      req =
        headers:
          'user-agent': 'MSIE'
      res = {}

      @.use_Flare(req,res).assert_Is_False()


