require 'fluentnode'
Jade_Service = require '../../src/services/Jade-Service'

describe "| services | Jade-Service |", ()->

  jade_File    = null
  mixin_File   = null
  compile_Path = null
  jade_Path    = null
  jade_Html    = null

  before ->
    compile_Path   = '_tmp_Jade_Compilation'.assert_Folder_Not_Exists()
    jade_Path      = '_tmp_Jade_Files'      .assert_Folder_Not_Exists()
    jade_File      = 'test.jade'
    mixin_File     = 'mixin.jade'
    jade_Contents  = "include mixin.jade\nh2 in-jade\n+test"
                      #+test"
    mixin_Contents = "mixin test\n  h3 inside-mixin"
    jade_Html      = '<h2>in-jade</h2><h3>inside-mixin</h3>'
    jade_Path.folder_Create()
    mixin_Contents.save_As jade_Path.path_Combine mixin_File
    jade_Contents. save_As jade_Path.path_Combine jade_File

    after ->
      compile_Path.folder_Delete_Recursive().assert_Is_True()
      jade_Path   .folder_Delete_Recursive().assert_Is_True()

  it 'constructor', ()->
    using new Jade_Service(),->
      @.assert_Is_Object()
      @.apply_Highlight         .assert_Is_Function()
      @.calculate_Compile_Path  .assert_Is_Function()
      @.cache_Enabled           .assert_Is_Function()
      @.compile_JadeFile_To_Disk.assert_Is_Function()
      @.render_Jade_File        .assert_Is_Function()

  it 'apply_Highlight', ->
    no_Pre             = '<b>aaaa</b>'
    with_Pre           = no_Pre.append '<pre>var a=12;<br>b = function {}</pre>'
    with_Pre_Highlight = '<b>aaaa</b><pre><span class=\"keyword\">var</span> a=<span class=\"number\">12</span>;\nb = <span class=\"keyword\">function</span> {}</pre>'
    using new Jade_Service(),->
      @.apply_Highlight(no_Pre  ).assert_Is no_Pre
      @.apply_Highlight(with_Pre).assert_Is with_Pre_Highlight

  it 'cache_Enabled', ()->
    _global_config = global.config                                # save it so it can be restored

    global.config = tm_design : jade_Compilation_Enabled : false
    using new Jade_Service(),->
      @.cache_Enabled()    .assert_Is_False()

    global.config = tm_design : jade_Compilation_Enabled : true
    using new Jade_Service(),->
      @.cache_Enabled()    .assert_Is_True()

    global.config = null
    using new Jade_Service(),->
      @.cache_Enabled()    .assert_Is_False()

    global.config = _global_config


  it 'calculate_Compile_Path', ()->
    using new Jade_Service(), ->
      @.folder_Jade_Compilation = compile_Path
      using @.calculate_Compile_Path, ->
        @("aaa"              ).assert_Is compile_Path.real_Path().path_Combine('aaa.js'             )
        @("aaa/bbb"          ).assert_Is compile_Path.real_Path().path_Combine('aaa-bbb.js'         )
        @("aaa/bbb/ccc"      ).assert_Is compile_Path.real_Path().path_Combine('aaa-bbb-ccc.js'     )
        @("aaa/bbb.jade"     ).assert_Is compile_Path.real_Path().path_Combine('aaa-bbb.jade.js'    )
        @("aaa/bbb.ccc.jade" ).assert_Is compile_Path.real_Path().path_Combine('aaa-bbb.ccc.jade.js')

      @.folder_Jade_Compilation = null
      assert_Is_Null @.calculate_Compile_Path "aaa"

  it 'calculate_Jade_Path',->
      using new Jade_Service(), ->
        @.folder_Jade_Files = jade_Path
        using @.calculate_Jade_Path, ->
          @("a.jade"    ).assert_Is jade_Path.path_Combine 'a.jade'
          @("/a.jade"   ).assert_Is jade_Path.path_Combine 'a.jade'
          @("a/b.jade"  ).assert_Is jade_Path.path_Combine 'a/b.jade'
          @("/a/b.jade" ).assert_Is jade_Path.path_Combine 'a/b.jade'

        @.folder_Jade_Files = null
        assert_Is_Null @.calculate_Jade_Path "aaa"

  it 'compile_JadeFile_To_Disk', ()->
    using new Jade_Service(), ->
      @.folder_Jade_Files = jade_Path
      @.folder_Jade_Compilation = compile_Path

      compiled_File    = @.calculate_Compile_Path(jade_File)
      @.compile_JadeFile_To_Disk(jade_File).assert_Is_True()
      jadeTemplate  = require(compiled_File.real_Path());
      jadeTemplate.assert_Is_Function()
      jadeTemplate().assert_Is_String()
      html = jadeTemplate();
      html.assert_Is jade_Html

      global.config  = null
      @.compile_JadeFile_To_Disk('a').assert_Is_False()

  it 'renderJadeFile', ()->
    global.config = tm_design :
      folder_Jade_Files       : jade_Path
      folder_Jade_Compilation : compile_Path

    using new Jade_Service(),->

        @.render_Jade_File('a').assert_Is("");
        @.render_Jade_File(jade_File, { structure: []}).assert_Is_Not ''
        @.render_Jade_File(jade_File                  ).assert_Is jade_Html
        #@.render_Jade_File(jade_File,{loggedIn:false} ).assert_Is '<h2>abc</h2><h1>false</h1>'
        #@.render_Jade_File(jade_File,{loggedIn:true}  ).assert_Is '<h2>abc</h2><h1>true</h1>'
