root_Folder         = process.cwd().path_Combine '../../'
p3p_FilePath        = '/code/TM_Static/w3c/p3p.xml'     #location of the P3P file
fullp3p_FilePath    = '/code/TM_Static/w3c/public.xml'  #location of the full P3P policy file
Router              = null

class P3P_Policy_Controller
  dependencies : () ->
    {Router}     = require 'express'

  constructor: (req, res)->
    @.dependencies()
    @.req            = req;
    @.res            = res;

  renderPolicy_File: ()=>
    xmlData =   (root_Folder.path_Combine p3p_FilePath).file_Contents()
    @.res.set('Content-Type', 'text/xml')
    @.res.send xmlData

  renderPublicPolicy_File: ()=>
    xmlData =   (root_Folder.path_Combine fullp3p_FilePath).file_Contents()
    @.res.set('Content-Type', 'text/xml')
    @.res.send xmlData


  routes:  ()=>
    using new Router(), ->
      @.get  '/w3c/p3p.xml' ,    (req, res)=> new P3P_Policy_Controller(req, res).renderPolicy_File()
      @.get  '/public.xml'   ,   (req, res)=> new P3P_Policy_Controller(req, res).renderPublicPolicy_File()

module.exports = P3P_Policy_Controller