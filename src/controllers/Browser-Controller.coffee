{Router} = require 'express'

#references
# - http://webaim.org/blog/user-agent-string-history/

# firefox on osx: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:39.0) Gecko/20100101 Firefox/39.0
# chrome on osx: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36
# safari on osx: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_4) AppleWebKit/600.7.12 (KHTML, like Gecko) Version/8.0.7 Safari/600.7.12

# main source: http://www.useragentstring.com/pages/Browserlist/

class Browser_Controller
  constructor: ->

  detect: (req, res)=>
    res.send req.headers?['user-agent'];

  is_5_0: (req)=>
    return req.headers?['user-agent']?.contains('Mozilla/5.0') || false

  is_Chrome: (req)=>
    return req.headers?['user-agent']?.contains('Chrome') || false

  is_IE_11: (req)=>
    return req.headers?['user-agent']?.contains('MSIE 11') || false

  is_Firefox: (req)=>
    return req.headers?['user-agent']?.contains('Firefox') || false

  is_Safari: (req)=>
    return (req.headers?['user-agent']?.contains('Safari') and not req.headers?['user-agent']?.contains('Chrome') ) || false

  use_Flare: (req, res)=>
    return true if @.is_Chrome(req ) and @.is_5_0(req)
    return true if @.is_IE_11(req  ) and @.is_5_0(req)
    return true if @.is_Firefox(req) and @.is_5_0(req)
    return true if @.is_Safari(req ) and @.is_5_0(req)

    return false

  redirect_Root: (req, res)=>
    if @.use_Flare(req)
      res.redirect '/angular/user/index'
    else
      res.redirect '/jade'

  redirect_Article: (req, res)=>
    if @.use_Flare(req)
      res.redirect '/angular/user' +req.url
    else
      res.redirect '/jade'  +req.url

  redirect_Search: (req, res)=>
    if @.use_Flare(req)
      res.redirect '/angular/user/index?text=' +req.query.text
    else
      res.redirect '/jade'  +req.url

  routes: =>
    browser_Controler = @
    using new Router(),->
      @.get '/browser'            , (req, res) -> browser_Controler.detect(req, res)
      #@.get '/use_Flare'         , (req, res) -> res.send browser_Controler.use_Flare(req)
      @.get '/'                   , (req, res) -> browser_Controler.redirect_Root(req, res)
      @.get '/browser-detect'     , (req, res) -> browser_Controler.redirect_Root(req, res)
      @.get '/article/*'          , (req, res) -> browser_Controler.redirect_Article(req, res)
      @.get '/search'             , (req, res) -> browser_Controler.redirect_Search(req,res)


module.exports = Browser_Controller