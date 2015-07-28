require('coffee-script/register')
Side_Data = require('../../TM_Shared/src/Site-Data')

site_Data = new Side_Data()

#log('[SiteData] loading data from ' + site_Data.siteData_Folder())

options = site_Data.load_Options()

original = options.json_Str().json_Parse()

config =
  options   : options
  original  : original
  site_Data : site_Data
  restore   : -> config.options = config.original.json_Str().json_Parse()

module.exports = config
