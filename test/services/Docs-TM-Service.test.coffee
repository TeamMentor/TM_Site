Docs_TM_Service   = require('../../src/services/Docs-TM-Service')

describe "| services | Docs-TM-Service.test", ()->

  docs_TM_Service = null

  before ->
    docs_TM_Service = new Docs_TM_Service()
    @timeout(4000)

  it 'check docs_TM_Service default fields', ()->
    using new Docs_TM_Service(),->
      @                    .assert_Is_Object()
      @._tmSite            .assert_Is_String()
      @._tmWebServices     .assert_Is_String()
      @.getArticlesMetadata.assert_Is_Function()
      @.getLibraryData     .assert_Is_Function()

      @.disableCache = false
      @.root_Path.assert_Folder_Exists()
      @.libraryDirectory.assert_Folder_Exists()

  it 'getArticlesMetadata', ()->

    docs_TM_Service.getArticlesMetadata (articlesMetadata)->
      using articlesMetadata, ->
        @                  .assert_Is_Object()
        @._numberOfArticles.assert_Is_Number()
        @._numberOfArticles.assert_Above 44

        assert_Is_Undefined articlesMetadata['00000000-0000-0000-0000-000000000000']

        using articlesMetadata["23a3c023-fc74-46fe-9a6e-e7ec2d136335"],->
          @           .assert_Is_Object()
          @.Title     .assert_Is 'Installing TEAM Mentor Eclipse Plugin for Fortify'
          @.Technology.assert_Is 'Eclipse Plugin'
          @.Phase     .assert_Is 'NA'
          @.Type      .assert_Is 'Documentation'
          @.Category  .assert_Is 'Administration'


  it 'getLibraryData', ()->

    docs_TM_Service.getLibraryData (libraryData)->
      using libraryData,->
        @.assert_Is_Array().assert_Not_Empty()

        using libraryData.first(), ->
          library   = @.assert_Is_Object()
          @.Title      .assert_Is_String()
          @.Views      .assert_Is_Array()
          @.Folders    .assert_Is_Array()
          @.Articles   .assert_Is_Object()

          using @.Views.first(),->
            view    = @.assert_Is_Object()
            @.Title    .assert_Is_String()
            @.Articles .assert_Is_Array().assert_Not_Empty()
                                        .first().Id.assert_Is_String()
            article_Id = @.Articles.first().Id
            article    = library.Articles[article_Id].assert_Is_Object()

            library.Title .assert_Is 'TM Documentation'
            view   .Title .assert_Is 'About TEAM Mentor'

            using article, ->
              @.Title     .assert_Is 'Introduction to TEAM Mentor'
              @.Technology.assert_Is ''
              @.Phase     .assert_Is 'NA'
              @.Type      .assert_Is ''
              @.Category  .assert_Is ''

  it 'json_Files', ->
    docs_TM_Service.json_Files (json_Files)->
      json_Files.assert_Size_Is_Above 10              # there should be at least 40 help files

  it 'article_Data', ->
    using docs_TM_Service, ->
      @.json_Files (json_Files)=>
        ids = (json_File.file_Name_Without_Extension() for json_File in json_Files)
        for id in ids
          data = @.article_Data id
          data.id.assert_Is id