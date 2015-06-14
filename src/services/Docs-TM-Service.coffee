fs             = null
path           = null
request        = null
Cache_Service  = null

class Docs_TM_Service

  dependencies: ->
    fs             = require('fs')
    path           = require('path')
    request        = require('request')
    Cache_Service  = require('teammentor').Cache_Service

  constructor: ->
    @.dependencies()

    @._json_Files            = null

    @.disableCache           = false
    @._name                  = 'docs'
    @._tmSite                = 'https://docs.teammentor.net'
    @._tmWebServices         = '/Aspx_Pages/TM_WebServices.asmx/'
    @.cache                  = new Cache_Service("docs_cache")
    @.libraryDirectory       = global.config?.tm_design?.folder_Docs_Json


  getFolderStructure_Libraries: (callback)=>
    @.library_File  = @.libraryDirectory.path_Combine '/Library/TM Documentation.json'
    json_Library    = @.library_File?.load_Json().guidanceExplorer?.library?.first()
    callback json_Library

  getArticlesMetadata: (callback)=>
    json_Folder      = @.libraryDirectory.path_Combine 'Library'
    json_Files       = json_Folder.files_Recursive '.json'
    articlesMetadata = {}
    articlesMetadata._numberOfArticles = 0
    for file in json_Files
      jsonFile = file.load_Json().TeamMentor_Article
      data    = jsonFile?.Metadata?.first()
      if data
        using data, ->
          metadata =
            Id         : @.Id         .first(),
            Title      : @.Title      .first(),
            Technology : @.Technology?.first(),
            Phase      : @.Phase?.     first(),
            Type       : @.Type?.      first(),
            Category   : @.Category?.  first()

          articlesMetadata[metadata.Id]= metadata;
          articlesMetadata._numberOfArticles++;
    callback articlesMetadata;

  getLibraryData: (callback)->
    @.getFolderStructure_Libraries (tmLibrary)=>
      if not tmLibrary
        callback null
      @.getArticlesMetadata (articlesMetadata)=>
        libraryData = [];
        library =
                  Title   : tmLibrary["$"].caption
                  Folders : [],
                  Views   : [],
                  Articles: {}

        tmLibrary.guidanceItems = [];
        views                   = tmLibrary?.libraryStructure?.first()?.view

        for tmView in views
          view =
            Title: tmView['$'].caption,
            Articles: []
          items = tmView.items.first().item

          for guidanceItemId in items                                  # Finding ids in views
            articleMetadata = articlesMetadata[guidanceItemId];
            if(articleMetadata?)
              view   .Articles.push(articleMetadata);
              library.Articles[articleMetadata.Id] = articleMetadata;

          library.Views.push(view);                                    # Adding view to library
          libraryData.push(library);
        callback libraryData


  json_Files: (callback)=>
    if not @._json_Files
      json_Folder   = @.libraryDirectory.append("/Articles_Html")
      @._json_Files = json_Folder.files_Recursive(".json")
    callback @._json_Files

  article_Data: (articleId)=>
    @.json_Files (jsonFiles)=>
      article_File = jsonFile for jsonFile in jsonFiles when jsonFile.contains(articleId)
      if article_File and article_File.file_Exists()
        return article_File.load_Json()
      return null

module.exports = Docs_TM_Service