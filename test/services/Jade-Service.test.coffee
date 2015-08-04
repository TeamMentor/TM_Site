Jade_Service = require '../../src/services/Jade-Service'
config       = require '../../src/config'

describe "| services | Jade-Service |", ()->

  jade_File    = null
  mixin_File   = null
  compile_Path = null
  jade_Path    = null
  jade_Html    = null

  beforeEach ->
    '_tmp_Jade_Compilation'.folder_Delete_Recursive()
    '_tmp_Jade_Files'.folder_Delete_Recursive()
    compile_Path   = '_tmp_Jade_Compilation'.assert_Folder_Not_Exists()
    jade_Path      = '_tmp_Jade_Files'      .assert_Folder_Not_Exists()
    jade_File      = 'test.jade'
    mixin_File     = 'mixin.jade'
    jade_Contents  = "include mixin.jade\nh2 in-jade\n+test"
                      #+test"
    mixin_Contents = "mixin test\n  h3 inside-mixin\n  h5= loggedIn"
    jade_Html      = '<h2>in-jade</h2><h3>inside-mixin</h3><h5></h5>'
    jade_Path.folder_Create()
    mixin_Contents.save_As jade_Path.path_Combine mixin_File
    jade_Contents. save_As jade_Path.path_Combine jade_File

    config.options.tm_design.folder_Jade_Files       =  jade_Path
    config.options.tm_design.folder_Jade_Compilation = compile_Path

    afterEach ->
      compile_Path.folder_Delete_Recursive().assert_Is_True()
      jade_Path   .folder_Delete_Recursive().assert_Is_True()

      config.restore()

  it 'constructor', ()->
    using new Jade_Service(),->
      @.assert_Is_Object()
      @.apply_Highlight         .assert_Is_Function()
      @.calculate_Compile_Path  .assert_Is_Function()
      @.cache_Enabled           .assert_Is_Function()
      @.compile_JadeFile_To_Disk.assert_Is_Function()
      @.render_Jade_File        .assert_Is_Function()

      @.root_Path.assert_Folder_Exists()
      @.root_Path.path_Combine('code').assert_Folder_Exists()
      @.root_Path.path_Combine('data').assert_Folder_Exists()
      @.root_Path.path_Combine('config').assert_Folder_Exists()

  it 'apply_Highlight', ->
    no_Pre             = '<b>aaaa</b>'
    with_Pre           = no_Pre.append '<pre>var a=12;<br>b = function {}</pre>'
    with_Pre_Highlight = '<b>aaaa</b><pre><span class=\"keyword\">var</span> a=<span class=\"number\">12</span>;\nb = <span class=\"keyword\">function</span> {}</pre>'
    using new Jade_Service(),->
      @.apply_Highlight(no_Pre  ).assert_Is no_Pre
      @.apply_Highlight(with_Pre).assert_Is with_Pre_Highlight

  it 'cache_Enabled', ()->

    config.options.tm_design.jade_Compilation_Enabled = false
    using new Jade_Service(),->
      @.cache_Enabled()    .assert_Is_False()

    config.options.tm_design.jade_Compilation_Enabled = true
    using new Jade_Service(),->
      @.cache_Enabled()    .assert_Is_True()


  it 'calculate_Compile_Path', ()->
    using new Jade_Service(), ->
      @.folder_Jade_Compilation = -> compile_Path
      using @.calculate_Compile_Path, ->
        @("aaa"              ).assert_Is compile_Path.real_Path().path_Combine('aaa.js'             )
        @("aaa/bbb"          ).assert_Is compile_Path.real_Path().path_Combine('aaa-bbb.js'         )
        @("aaa/bbb/ccc"      ).assert_Is compile_Path.real_Path().path_Combine('aaa-bbb-ccc.js'     )
        @("aaa/bbb.jade"     ).assert_Is compile_Path.real_Path().path_Combine('aaa-bbb.jade.js'    )
        @("aaa/bbb.ccc.jade" ).assert_Is compile_Path.real_Path().path_Combine('aaa-bbb.ccc.jade.js')

    using new Jade_Service(), ->
      @.folder_Jade_Compilation = -> undefined
      assert_Is_Undefined @.folder_Jade_Compilation()
      assert_Is_Null @.calculate_Compile_Path "aaa"

  it 'cache_Hashes_File, cache_Hashes_Get, cache_Hashes_Set',->
    config.options.tm_design.jade_Compilation_Enabled = true
    using new Jade_Service(), ->
      @.folder_Jade_Compilation = -> compile_Path
      @.cache_Hashes_File().assert_File_Deleted()
      @.cache_Hashes_File().assert_File_Not_Exists()
      @.cache_Hashes_Get().assert_Is {}
      @.jade_Compilation_Enabled().assert_Is_True()

      target = jade_Path.path_Combine jade_File
      @.render_Jade_File(target).assert_Is(@.render_Jade_File target)
      @.cache_Hashes_File().assert_File_Exists()

      contents_1 = @.cache_Hashes_File().file_Contents()
      target.file_Contents().replace('in-jade', 'aaaa').save_As(target)
      @.render_Jade_File(target).assert_Is_Not contents_1






  it 'calculate_Jade_Path',->
      using new Jade_Service(), ->
        using @.calculate_Jade_Path, ->
          @("a.jade"    ).assert_Is jade_Path.path_Combine 'a.jade'
          @("/a.jade"   ).assert_Is jade_Path.path_Combine 'a.jade'
          @("a/b.jade"  ).assert_Is jade_Path.path_Combine 'a/b.jade'
          @("/a/b.jade" ).assert_Is jade_Path.path_Combine 'a/b.jade'

        @.folder_Jade_Files = -> null
        assert_Is_Null @.calculate_Jade_Path "aaa"

  it 'calculate_Jade_Path (via config options)',->
    using new Jade_Service(), ->
      jade_File = @.calculate_Jade_Path('test.jade')
      jade_File.assert_File_Exists()
      @.calculate_Jade_Path(jade_File).assert_Is jade_File
      config.options.tm_design.folder_Jade_Files = 'aaaa'
      @.calculate_Jade_Path('test.jade').assert_Is @.root_Path.path_Combine('aaaa/test.jade')
      config.restore()
      @.calculate_Jade_Path('test.jade').assert_Contains config.options.tm_design.folder_Jade_Files.path_Combine('test.jade')

  it 'compile_JadeFile_To_Disk', ()->
    using new Jade_Service(), ->

      compiled_File    = @.calculate_Compile_Path(jade_File)
      @.compile_JadeFile_To_Disk(jade_File).assert_Is_True()
      jadeTemplate  = require(compiled_File.real_Path());
      jadeTemplate.assert_Is_Function()
      jadeTemplate().assert_Is_String()
      html = jadeTemplate();
      html.assert_Is jade_Html

      @.compile_JadeFile_To_Disk('a').assert_Is_False()

  it 'renderJadeFile', ()->



    using new Jade_Service(),->

        @.render_Jade_File('a').assert_Is("");
        @.render_Jade_File(jade_File, { structure: []}).assert_Is_Not ''
        @.render_Jade_File(jade_File                  ).assert_Is jade_Html
        @.render_Jade_File(jade_File,{loggedIn:false} ).assert_Is jade_Html.replace('<h5></h5>','<h5>false</h5>')
        @.render_Jade_File(jade_File,{loggedIn:true}  ).assert_Is jade_Html.replace('<h5></h5>','<h5>true</h5>')

    config.restore()
