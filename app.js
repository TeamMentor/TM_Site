/*jslint node: true */
"use strict";
require('coffee-script/register');                      // enable coffee-script support
require('fluentnode');                                  // register fluentnode files
//require('./test/set-globals')                         // tmp until this is wired properly
//log(global.config.json_Pretty())

process.env.TM_SITE_DATA = "SiteData_TM";

var Side_Data = require('../TM_Shared/src/Site-Data');
global.config = new Side_Data().load_Options()
log('------------------------------------')
log(global.config);
log('------------------------------------')

var Express_Service   = require('./src/services/Express-Service');
var Analytics_Service = require('./src/services/Analytics-Service');
new Express_Service()
      .setup()
      .start();
new Analytics_Service()
      .setup();

