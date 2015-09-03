fs        = null
path      = null
jade      = null
cheerio   = null
config    = null
Highlight = null
Router    = null

crypto = require 'crypto'
String::checksum = (algorithm, encoding)->
  crypto.createHash(algorithm || 'md5')
        .update(@.toString(), 'utf8')
        .digest(encoding || 'hex')

class JadeService

    dependencies: ()->
      fs          = require 'fs'
      path        = require 'path'
      jade        = require 'jade'   # 4 ms (with preloading)
      cheerio     = require 'cheerio'
      config      = require '../config'
      {Highlight} = require 'highlight'
      {Router}    = require 'express'

    constructor: (options)->
      @.dependencies()
      @.root_Path                = __dirname.path_Combine '../../../../'
      @.mixin_Extends            = "..#{path.sep}_layouts#{path.sep}page_clean"

    apply_Highlight: (html)=>
      if html.not_Contains('<pre>')
        return html
      $ = cheerio.load(html)
      $('pre').each (i,elem)->
        if $(elem).text().trim() is ''
          $(elem).remove()
        else
          $(elem).find($('br')).replaceWith('\n')
          $(elem).replaceWith($('<pre>' + Highlight($(elem).text()) + '</pre>'))
      $.html()

    cache_Enabled: ()=>
      @.jade_Compilation_Enabled()

    cache_Hashes_File: ()=>
      @.folder_Jade_Compilation().path_Combine('compilation_Hashes.json')

    cache_Hashes_Get: ()=>
      @.cache_Hashes_File().load_Json() || {}

    cache_Hashes_Set: (key,value)=>
      cache_Hashes = @.cache_Hashes_Get()
      cache_Hashes[key] = value
      cache_Hashes.save_Json @.cache_Hashes_File()

    calculate_Compile_Path: (fileToCompile)=>
      compile_Folder = @.folder_Jade_Compilation()
      if compile_Folder
        if compile_Folder.folder_Not_Exists()
          compile_Folder.folder_Create()
        compile_Folder = compile_Folder.real_Path()
        fileToCompile  = fileToCompile.remove(@.root_Path)
        return compile_Folder.path_Combine(fileToCompile.to_Safe_String() + '.js')
      return null

    calculate_Jade_Path: (jade_File)=>
      if jade_File.file_Exists()
        return jade_File

      if @.folder_Jade_Files()
        if @.folder_Jade_Files?().folder_Exists()
          return @.folder_Jade_Files().path_Combine(jade_File)
        return @.root_Path.path_Combine @.folder_Jade_Files()
                          .path_Combine jade_File
      return null


    compile_JadeFile_To_Disk: (target)=>
      jade_File = target

      if (not jade_File)
        return false

      if jade_File.file_Not_Exists()
        jade_File = @.calculate_Jade_Path(jade_File)

      if jade_File.file_Not_Exists() then return false

      targetFile_Path = @.calculate_Compile_Path(jade_File);
      targetFile_Path.file_Delete()

      js_Code = jade.compileClient(jade_File.file_Contents() , { filename:jade_File, compileDebug : false} );

      exportCode =  'var jade = require(\'jade/lib/runtime.js\'); \n' +
                    'module.exports = ' + js_Code;

      exportCode.save_As(targetFile_Path).file_Exists()
      return targetFile_Path

    folder_Jade_Files        : -> config.options.tm_design.folder_Jade_Files
    folder_Jade_Compilation  : -> @.calculate_Jade_Path('').path_Combine '../TM_Website/.tmCache/jade-Compilation'
    folder_Static_Files      : -> @.calculate_Jade_Path('').path_Combine '../TM_Static'
    jade_Compilation_Enabled : -> config.options.tm_design.jade_Compilation_Enabled || false

    render_Jade_File: (jadeFile, params)=>

      params = params || {}

      params.custom_navigation = global.custom?.custom_navigation

      if params.article_Html
        params.article_Html = @.apply_Highlight(params.article_Html)

      jadeFile_Path   = @.calculate_Jade_Path(jadeFile)
      targetFile_Path = @.calculate_Compile_Path(jadeFile_Path);

      if (@.cache_Enabled() is false)
        if jadeFile_Path?.file_Exists()
          return jade.renderFile(jadeFile_Path,params)
        return ""

      jade_File_Contents = jadeFile_Path.file_Contents()
      if not jade_File_Contents
        return ""

      if targetFile_Path?.file_Exists()                                                # check if jadeFile contents has been changed
        if (@.cache_Hashes_Get()[jadeFile_Path] isnt jade_File_Contents.checksum())
          "[jade-compilation] detected file change to: #{jadeFile.file_Name()}".log()
          delete require.cache[targetFile_Path]                                       # invalidate cache
          targetFile_Path.file_Delete()                                               # delete compiled file

      if targetFile_Path.file_Not_Exists() and @.compile_JadeFile_To_Disk(jadeFile_Path) is false
        return "";

      @.cache_Hashes_Set(jadeFile_Path , jade_File_Contents.checksum())              # save hash
      return require(targetFile_Path)(params);

    render_Mixin: (file, mixin, params)=>
      safeFile      = file.to_Safe_String()                                   # only allow letter, numbers, comma, dash and underscore
      safeMixin     = mixin.to_Safe_String()
      dummyJade     = @.calculate_Jade_Path('/_mixins/tmp.jade')              # file to be provided to jade.compile (used to resolve the mixin file path)
      code = "extends #{@.mixin_Extends}    \n" +                               # add html head and body (with TM css, but no nav bar)
             "include #{safeFile}.jade      \n" +                             # imports mixin file
             "block content                 \n" +                             # where rendered mixin will be placed
             "  +#{safeMixin}                 "                               # mixin to render
      return jade.compile(code, {filename: dummyJade })(params)

    routes: ()=>
      jade_Service = @
      using new Router(), ->
        @.get '/index.html'               , (req, res)-> res.send jade_Service.render_Jade_File 'guest/default.jade'
        @.get '/guest/:page.html'         , (req, res)-> res.send jade_Service.render_Jade_File 'guest/' + req.params.page + '.jade'
        @.get '/guest/:page'              , (req, res)-> res.send jade_Service.render_Jade_File 'guest/' + req.params.page + '.jade'

module.exports = JadeService
