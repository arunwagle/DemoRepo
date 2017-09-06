/**
 * Copyright 2015 IBM Corp. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

  var express    = require('express'),
  app          = express(),
  skipper = require('skipper'),
  watson       = require('watson-developer-cloud'),
  extend       = require('util')._extend,
  i18n         = require('i18next'),
  bodyParser   = require('body-parser'),
  Cloudant     = require('cloudant');

  // agent = require('bluemix-autoscaling-agent');
  app.use(require("skipper")());

//i18n settings
require('./config/i18n')(app);

// Bootstrap application settings
require('./config/express')(app);


// require('./config/ibmgraph')(app);

require('./routes/node_cf')(app);
//
// require('./routes/generic')(app);


// Create the Alchemy API service wrapper
// If no API Key is provided here, the watson-developer-cloud@2.x.x library will check for an ALCHEMY_LANGUAGE_API_KEY environment property and then fall back to the VCAP_SERVICES property provided by Bluemix.
var alchemyLanguage = watson.alchemy_language({
  // api_key: 'API_KEY'
});


// Initialize the library with my account.
var cloudant = Cloudant({instanceName: 'SVC-Cloudant', vcapServices: JSON.parse(process.env.VCAP_SERVICES)});
var alchemy_generic_db = cloudant.db.use("alchemy_generic_db");

app.get('/', function(req, res) {
  res.render('home');
});

// app.get('/gh', function(req, res) {
//   res.render('genericHome');
// });

app.get('/mh', function(req, res) {
  res.render('mh');
});

app.get('/ih', function(req, res) {
  res.render('ih');
});

app.get('/cf', function(req, res) {
  res.render('cf');
});

app.get('/cc', function(req, res) {
  res.render('cc');
});

app.get('/settings', function(req, res) {
  res.render('settings');
});

app.get('/watsonsettings', function(req, res) {
  res.render('watsonsettings');
});

app.get('/uploadsettings', function(req, res) {
  res.render('uploadsettings');
});

app.get('/ah', function(req, res) {
  res.render('alchemyHome');
});
app.get('/carAccident-nlp', function(req, res) {
  res.render('carAccident-nlp');
});


// cloudant.db.list(function(err, allDbs) {
//   console.log('All my databases: %s', allDbs.join(', '))
// });

// Alchemy language methods
app.post('/api/alchemy/:method', function(req, res, next) {
  var method = req.params.method;

  if(method === "saveToCloudant"){
    var data = req.body;
    console.log("data to be saved=" + data);
    alchemy_generic_db.insert(data, function(err, body, header) {
      if (err) {
        return console.log('[alchemy_generic_db.insert] ', err.message);
      }

      console.log('You have inserted the data.');
      console.log(body);
    });

    return res.json("success");
  }
  else if (typeof alchemyLanguage[method] === 'function') {
    alchemyLanguage[method](req.body, function(err, response) {
      if (err) {
        return next(err);
      }
      return res.json(response);
    });
  }
  else {
    next({code: 404, error: 'Unknown method: ' + method });
  }
});

// error-handler settings
require('./config/error-handler')(app);


var port = process.env.PORT || process.env.VCAP_APP_PORT || 3000;
app.listen(port);
console.log('listening at:', port);
