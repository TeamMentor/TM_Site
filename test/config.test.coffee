describe 'config',->
  it 'Check default import', ->
    using require('../src/config'), ->
      @.options.assert_Is_Object()
      @.options.assert_Is @.original

  it 'Check change for Unit Tests', ->
    config     = require '../src/config'
    {options}  = require '../src/config'
    {original} = require '../src/config'


    config.options = { a : 42}       # change it

    options.assert_Is original

    {options} = require '../src/config'
    options.assert_Is  { a : 42}

    config.options = original

    {options} = require '../src/config'
    options.assert_Is original