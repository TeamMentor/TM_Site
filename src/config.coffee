Side_Data = require('../../TM_Shared/src/Site-Data')

site_Data = new Side_Data()

#log('[SiteData] loading data from ' + site_Data.siteData_Folder())

options = site_Data.load_Custom_Code()
                   .load_Options()

module.exports =
  options   : options
  original   : options
  site_Data : site_Data
