Anonymous_Service       = require('./../../src/services/Anonymous-Service')
expect                  = require("chai").expect
assert                  = require("chai").assert

# There is a race condition with this test which creates a nubmer of nasty side effects on other tests
xdescribe '| services | Anonymous-Service.test |', ->

  anonymous_service  = null

  before ->
    anonymous_service = new Anonymous_Service()

  it 'constructor()',->
    using new Anonymous_Service(), ->
      @.filename.assert_Is './.tmCache/_anonymousVisits'
      @.anonymousConfig.assert_Is_Not_Undefined
      @.anonymousConfig.allowAnonymousArticles.assert_Is_True
      @.anonymousConfig.allowedArticles.assert_Is 5
      @.anonymousConfig.cookieName.assert_Is 'X2ZpbmdlcnByaW50'
      @.anonymousConfig.expirationDays.assert_Is 30
      @.anonymousConfig.welcomeMessage.assert_Not_Empty()
      @.setup()                                                       # the prob is here since @.setup() will trigger async calls

