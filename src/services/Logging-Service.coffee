winston    = null

class Logging_Service

  dependencies: ()->
    winston    = require 'winston'

  constructor: (options)->
    @.dependencies()
    @.options          = options || {}
    @.log_Folder       = @.options.log_Folder || './.logs'
    @.log_File_Name    = @.options.log_File_Name || 'tm-design'
    @.log_File         = null
    @.logger           = null
    @.original_Console = null

  setup: =>
    @.log_File = @.log_Folder.folder_Create().path_Combine(@.log_File_Name)

    @.logger = new (winston.Logger)

    @.logger .add(   winston.transports.DailyRotateFile, { filename: @.log_File, datePattern: '.yyyy-MM-dd'} )
             .add(   winston.transports.Console        , { timestamp: true, level: 'verbose', colorize: true })

    global.logger      = @
    @.hook_Console()
    @

  add_Memory_Logger: ()=>
    @.logger.add(winston.transports.Memory ,{})
    @

  hook_Console: =>
    if(console.log.source_Code() is "function () { [native code] }")
      @.original_Console = console.log
      console.log        = (args...)=> @.info args...
      log '[Logging-Service] console hooked'

  restore_Console: =>
    if @.original_Console
      console.log = @.original_Console
      log 'Console restored'

  info: (data)=>
    @.logger.info data
    data

  log: (data)=>
    @.logger.info data
    data

  error: (data)=>
    @.logger.error data
    data

  info_Messages: ()=>
    @.logger.transports.memory.writeOutput

  error_Messages: ()=>
    @.logger.transports.memory.errorOutput

module.exports = Logging_Service