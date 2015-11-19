P3PPolicy_Controller = require('../../src/controllers/P3P-Policy-Controller')

describe.only '| controllers | P3PPolicy-Controller.test', ->
  p3p_Policy_Controller    = null

  before (done)->
    p3p_Policy_Controller = new P3PPolicy_Controller()
    done()

  it 'Get P3P policy file', (done)->
    req = {}
    res =
      set  :()->
      send : (data)->
        data.assert_Is_Not_Null()
        data.assert_Contains('<POLICY-REFERENCES>')
        done()

    using new P3PPolicy_Controller(req,res),->
      @.renderPolicy_File()

  it 'Get XML P3P  full policy file', (done)->
    req = {}
    res =
      set  :()->
      send : (data)->
        data.assert_Is_Not_Null()
        data.assert_Contains('<DATA ref="#business.name">TEAMMentor</DATA>')
        done()
    using new P3PPolicy_Controller(req,res),->
      @.renderPublicPolicy_File()

  describe 'routes',->
    it 'register_Routes',->
      paths = for item in p3p_Policy_Controller.routes().stack
        if item.route
          item.route.path
      paths.assert_Is [ '/w3c/p3p.xml','/public.xml']
