Logging_Service = require('./../../src/services/Logging-Service')

describe '| services | Logging-Service.test |', ->

  logging_Service = null

  beforeEach ->
    options =
      log_Folder    : './._test_logs'
      log_File_Name : 'tm-design-tests'
    logging_Service = new Logging_Service(options).setup()
                                                  .add_Memory_Logger()

  afterEach ()->
    using logging_Service, ->
      @.assert_Is_Object()

      return if not @.original_Console
      @.restore_Console()
      console.log    .assert_Is_Not global.info
      console.log    .assert_Is @.original_Console


  after ->
    using logging_Service, ->
      @.log_Folder.assert_Folder_Exists()
                  .folder_Delete_Recursive().assert_True()

  it 'constructor()',->
    using new Logging_Service(), ->
      @.options         .assert_Is {}
      @.log_Folder      .assert_Is './.logs'
      @.log_File_Name   .assert_Is 'tm-design'
      assert_Is_Null @.logger

  it 'setup', ()->
    using logging_Service, ->
      @.assert_Is_Instance_Of Logging_Service
      logger.assert_Is @
      @.options   .assert_Is { log_Folder: './._test_logs', log_File_Name:  'tm-design-tests'}
      @.log_Folder.assert_Folder_Exists()
      @.logger.info('setup test')
      @.logger.transports.memory.writeOutput.assert_Is ['info: setup test']



  it 'info', ()->
    using logging_Service, ->
      message = '[Logging-Service.test] Testing info'
      @.info message
       .assert_Is message
      @.info_Messages().assert_Is ["info: #{message}"]

  it 'error', ()->
    using logging_Service, ->
      message = '[Logging-Service.test] Testing error'
      @.error message
       .assert_Is message
      @.error_Messages().assert_Is ["error: #{message}"]

  it 'log', ()->
    using logging_Service, ->
      message = '[Logging-Service.test] Testing log'
      @.log message
       .assert_Is message
      @.info_Messages().assert_Is ["info: #{message}"]


