'use strict';

var request = require('request-promise'); /* Note: using promise-friendly lib */
var Promise = require('bluebird');
var Q = require('q');
var fs = Promise.promisifyAll(require('fs'));
// var KafkaRest = require('kafka-rest');
var Cloudant     = require('cloudant');


// IBMGraph Service API
var apiURL;
var username;
var password;
var baseURL;
// TODO - Remove hard coding
var gName = "gtest36";
var deleteGraphName = "gtest35"


// cloudant
var db_vertexes;
var db_edges;
var db_issuelist;
var totalEdges;
var limit = 5000;
var skip = 0;
var pendingEdges=0;
var processedEdges=0;
var concurrentRequest = 2000;

// Retrieve Graph API from VCAP services
if (process.env.VCAP_SERVICES) {
  var vcapServices = JSON.parse(process.env.VCAP_SERVICES);
  console.log("Grapph vcapServices=" + JSON.stringify(vcapServices));
  var graphService = 'IBM Graph';
  if (vcapServices[graphService] && vcapServices[graphService].length > 0) {
    var tp3 = vcapServices[graphService][0];
    apiURL = tp3.credentials.apiURL;
    username = tp3.credentials.username;
    password = tp3.credentials.password;
    baseURL = apiURL.split('/g').join('');
  }

  //var cloudant = Cloudant({instanceName: 'SVC-Cloudant', vcapServices: JSON.parse(process.env.VCAP_SERVICES), plugin:'promises'});

  var cloudant = Cloudant({url: "https://arunwagle:sourceCode0520@arunwagle.cloudant.com", plugin:'promises'});
  cloudant.set_cors({ enable_cors: true, allow_credentials: true, origins: ["*"]}, function(err, data) {
    console.log(err, data);
  });
  db_vertexes = cloudant.db.use("db_cf_cc_vertexes_med_ref");
  db_edges = cloudant.db.use("db_cf_cc_edges_med_ref");
  db_issuelist = cloudant.db.use("db_cf_cc_issue_list_med");

  db_edges.view('totalEdgesDesign', 'totalEdges', {reduce:true}, function(err, body) {
    if (!err) {
      totalEdges = body.rows[0].value;
      console.log("*****totalEdges*****" + totalEdges);
    }
  });

  // Message HUM Configurations
  // var messagehubService = 'messagehub';
  // if (vcapServices[messagehubService] && vcapServices[messagehubService].length > 0) {
  //   var tp3 = vcapServices[messagehubService][0];
  //   kafkaRestAPIURL = tp3.credentials.kafka_rest_url;
  //   var kafka = new KafkaRest({ 'url': kafkaRestAPIURL, 'headers': {'X-Auth-Token': 'i32mLKpYLwobWqcS1iX2qZj3WnoWxpGw2LaLAAvmJHKtBhbi'}});
  //
  // }

}

// console.log(" db=" + db);

// START: Generate IBM Graph Session
var sessionToken;
var getTokenOpts = {
    method: 'GET',
    uri: baseURL + '/_session',
    auth: {user: username, pass: password},
    json: true
};

request(getTokenOpts).then(function (body) {
    sessionToken = 'gds-token ' + body['gds-token'];
})

console.log("sessionToken=" + sessionToken);
// END: Generate IBM Graph Session


var createGraph=function createGraph(id){
  return iCreateGraph(id).then(function(data){
    console.log(data);
  }).catch(function (err) {
    return err;
  });
}

var deleteGraph=function deleteGraph(){
  // console.log("createVertex: label:" + data.fields.label + ": id:" + data.id);
  var graphDeleteOpts = {
          method: 'DELETE',
          headers: {'Authorization': sessionToken},
          uri: baseURL + '/_graphs' + '/' + deleteGraphName
  };
  request(graphDeleteOpts).then(function (body) {
    return body;
  }).catch(function (err) {
    return err;
  });

  return "Request to delete graph submitted successfully";
}

// START: Create Schema
var createSchema=function createSchema(graphName){
  fs.readFileAsync('./public/json/cf/cc/graph/ccschema.json', 'utf-8').then(function (data) {
    // console.log('data= : ' + data);
    // JSON.parse(data.toString())
      //Now send the request to IBM Graph
      var postSchemaOpts = {
          method: 'POST',
          headers: {'Authorization': sessionToken},
          uri: baseURL + "/" + gName + "/" + '/schema',
          json: JSON.parse(data.toString())
      };
      return request(postSchemaOpts);
    }).then(function (body) {
      console.log('Successfully created schema and here is the response : ' +
          JSON.stringify(body));
  });
  return "Request to createSchema submitted successfully";
}
// END: Create Schema





var deleteVertex=function deleteVertex(graphName, data){
  // console.log("createVertex: label:" + data.fields.label + ": id:" + data.id);
  var vertexDeleteOpts = {
          method: 'DELETE',
          headers: {'Authorization': sessionToken},
          uri: baseURL + '/' + gName + '/vertices' + "/" + data.id,
  };
  return request(vertexDeleteOpts);

}


var loadVertexData=function loadVertexData(){
  // var t0 = performance.now();
  var hrstart = process.hrtime();
  console.log("API:loadVertexData:START ");
  // type:'vertex',
  db_vertexes.find({selector:{"processVertex":true}}).then(function(cldV){
    console.log("API:loadVertexData: Total Vertexes  " + cldV.docs.length);
    return Promise.map(cldV.docs, function(row){
        return iCreateVertex (gName, row);
    }, {concurrency: 100});
    // return getSampleVertexes();
  }).then(function (grphVArr) {
    // console.log("====All Vertexes processed now:grphVArr: Processed in Graph DB " + JSON.stringify(grphVArr));
    // var t1 = performance.now();
    var t1 = process.hrtime(hrstart);
    console.log("API:loadVertexData: All Vertexes created in Graph DB in " + (t1[0]) + " seconds.");
    var vertexPromise = Promise.map(grphVArr, function(row){
        // console.log("Vertex: row " + JSON.stringify(row));
        // graph id of the Vertex
        var gId = row.data[0].id;
        // cloudant id of the vertex
        var cId = row.data[0].properties.pid[0].value;

        // read the vertex document
        var readDocPromise = db_vertexes.get(cId);
        return readDocPromise.then(function(doc){
          // console.log('getttt: %s', JSON.stringify(doc));
          doc.gid=gId;
          return doc;
        });
    }, {concurrency: 100}).then(function(updateDocumentArr) {
      return Promise.map(updateDocumentArr, function(doc){
          // console.log("Vertex: row " + JSON.stringify(doc));
          var updateDocPromise = db_vertexes.insert(doc);
          return updateDocPromise;
      }, {concurrency: 100});
    });
    return Q.all([
      vertexPromise
    ]);

  }).then(function(updateDocumentArr) {
    var t2 = process.hrtime(hrstart);
    // console.log("updateDocumentArr:  " + JSON.stringify(updateDocumentArr));
    console.log("Done: API:loadVertexData: All Vertexes updated with Graph Ids in Cloudant: Total Docs updated:  " + updateDocumentArr[0].length + " in " + (t2[0]) + " seconds.");
  }).catch(function(err) {
    console.log('API:loadVertexData: something went wrong', err);
  });


  return "Load Vertex Data Request Sent";
}


// START: Load Edges data from Cloudant
var prepareEdgesData=function prepareEdgesData(){
  // {selector:{type:'edge'}}
  //type:'edge',
  var hrstart = process.hrtime();
  console.log("API:prepareEdgesData:START ");
  //, "limit": limit, "skip": skip
  db_edges.find({selector:{"type": "edge"}}).then(function(cldEArr){
    console.log('prepareEdgesData: find esges len = ', cldEArr.docs.length);
    return Promise.map(cldEArr.docs, function (row) {
      // console.log(' Edge Docs: row', row);
      var readSourcePromise = db_vertexes.find({selector:{_id:row.source_id}});
      return readSourcePromise.then(function(result){
        var gSrcId = result.docs[0].gid;
        // console.log('1. vertex g_source_id=', g_source_id);
        row.gSrcId=gSrcId;
        return row;
      }).then(function(row){
          var t1 = process.hrtime(hrstart);
          console.log("API:prepareEdgesData: Edges updated with source graphId in " + (t1[0]) + " seconds.");
          var readTargetPromise = db_vertexes.find({selector:{_id:row.target_id}});
          return readTargetPromise.then(function(result){
            var gTgtId = result.docs[0].gid;
            row.gTgtId=gTgtId;
            return row;
          });
      }).catch(function(err) {
        console.log('1...something went wrong', err);
        return err;
      });;

    },{concurrency: concurrentRequest});
  }).then(function(edgeDocs){
    var t2 = process.hrtime(hrstart);
    console.log("API:prepareEdgesData: Edges updated with target graphId in " + (t2[0]) + " seconds.");
    // console.log('Edge Documents: %s', JSON.stringify(edgeDocs));
    // return Promise.map(edgeDocs, function (row) {
    //     var updateDocPromise = db_edges.insert(row);
    //     return updateDocPromise;
    // },{concurrency: concurrentRequest});
    return db_edges.bulk({docs:edgeDocs}).then(function(cldEArr){
        return cldEArr;
    });

  }).then(function(updatedEdgeDocs){
    // processedEdges+=limit;
    // skip=processedEdges;
    // pendingEdges=totalEdges - processedEdges;
    // if(pendingEdges < limit){
    //   limit = pendingEdges;
    // }
    // console.log('processedEdges:' + processedEdges + " skip:" + skip + " pendingEdges:" + pendingEdges + " limit:" + limit);
    var t3 = process.hrtime(hrstart);
    console.log("API:prepareEdgesData: Edges updated successfully in Cloudant in " + (t3[0]) + " seconds.");

    console.log('Edges Updated successfully');
  }).catch(function(err) {
    console.log('something went wrong', err);
    return err;
  });

  return "prepare EdgesData Data Request Sent";

}

var loadEdgesData=function loadEdgesData(){
  var hrstart = process.hrtime();
  console.log("API:loadEdgesData:START ");

  db_edges.find({selector:{type:'edge'}}).then(function(cldEArr){
    // console.log('result= ', JSON.stringify(cldEArr));

    return Promise.map(cldEArr.docs, function (row) {
      // console.log('Edge Document id: %s', JSON.stringify(row));
      return iCreateEdge (gName, row);
    },{concurrency: concurrentRequest});

  }).then(function(updatedEdgeDocs){
    var t2 = process.hrtime(hrstart);
    console.log("API:loadEdgesData: Edges created successfully in GraphDB in " + (t2[0]) + " seconds.");

    console.log('Edges loaded into graph db successfully');
  }).catch(function(err) {
    console.log('something went wrong', err);
    return err.message;
  });

  return "Load Edges Data Request Sent";

}
// END: Load Edges data from Cloudant


var prepareIssuesData=function prepareIssuesData(){
  var hrstart = process.hrtime();
  console.log("API:prepareIssuesData:START ");

  db_vertexes.find({selector:{type:'vertex', "label": {"$eq": "month"}}}).then(function(cldEArr){
    console.log('prepareIssuesData: find month vertex len = ', cldEArr.docs.length);
    return Promise.map(cldEArr.docs, function(row){
        // console.log("Vertex: row " + JSON.stringify(row));
        // graph id of the Vertex
        var gId = row.gid;
        // cloudant id of the vertex
        var cId = row._id;

        // read the issue document
        var readDocPromise = db_issuelist.find({selector:{type:'issue', month_id:cId}});
        return readDocPromise.then(function(issueArr){
          // console.log('getttt: %s', JSON.stringify(issueArr));
          var updateDocPromiseArr = [];
          for (var i = 0; i < issueArr.docs.length; i++) {
            var doc = issueArr.docs[i];
            doc.g_month_id = gId;
            updateDocPromiseArr.push(doc);
          }
          return updateDocPromiseArr;
        });

    }, {concurrency: concurrentRequest});

  }).then(function(documentArr){
    var t2 = process.hrtime(hrstart);
    console.log("API:prepareIssuesData: Issues updates successfully in memory with month graph ids " + (t2[0]) + " seconds.");
    return Promise.filter(documentArr, function(row){
      // console.log('row and typeof value   %s', JSON.stringify(row) + " typeof" + typeof row._id);
      return row.length > 0;
    }, {concurrency: concurrentRequest}).reduce(function(prev, cur){
        return prev.concat(cur);
    }, []);
  }).then(function(issuesDocs){
    var t3 = process.hrtime(hrstart);
    console.log("API:prepareIssuesData: Issues filtered successfully in memory with month graph ids " + (t3[0]) + " seconds.");

    console.log('prepareIssuesData: fissuesDocs len = ', issuesDocs.length);
    // Dive array into subArrays as bulk update has limit with the size of request data
    var subDocsArr = [];
    while(issuesDocs.length) {
      subDocsArr.push(issuesDocs.splice(0,50000));
    }

    return Promise.map(subDocsArr, function(subDocs){
        var bulkUpdatePromise = db_issuelist.bulk({docs:subDocs});

        return bulkUpdatePromise.then(function(bulkUpdateArr){
          return bulkUpdateArr;
        });
    }, {concurrency: concurrentRequest});


  }).then(function(updateDocumentArr) {
    var t4 = process.hrtime(hrstart);
    console.log("API:prepareIssuesData: Issues updates successfully in Cloudant month graph ids " + (t4[0]) + " seconds.");

    console.log("Done: API:prepareIssuesData: Issues updated with Graph Ids ");
  }).catch(function(err) {
    console.log('API:prepareIssuesData: something went wrong', err);
    return err;
  });

  return "API:prepareIssuesData: Data Request Sent";

}

// START: Load Edges data from Cloudant
var loadIssuesData=function loadIssuesData(){
  var hrstart = process.hrtime();
  console.log("API:loadIssuesData:START ");

  db_issuelist.find({selector:{type:'issue'}}).then(function(cldIArr){
    console.log('loadIssuesData: find cldIArr len = ', cldIArr.docs.length);

    return Promise.map(cldIArr.docs, function (row) {
      // console.log('Issues Document id: %s', JSON.stringify(row));
      return iCreateIssue (gName, row);
    },{concurrency: concurrentRequest});

  }).then(function (grphVArr) {
    var t1 = process.hrtime(hrstart);
    console.log("API:loadIssuesData: Issues vertex created in Graph:  " + gName + " in " + (t1[0]) + " seconds.");

    return Promise.map(grphVArr, function (row) {

      var gIssueId = row.data[0].id;
      var gMonthId = row.data[0].properties.g_month_id[0].value;

      var body = {
        'label': 'is_issue',
        'outV': gMonthId,
        'inV': gIssueId,
        "properties": {
          "received_date": row.data[0].properties.received_date[0].value
        }
      };

      var edgeCreateOpts = {
              method: 'POST',
              headers: {'Authorization': sessionToken},
              uri: baseURL + '/' + gName + '/edges',
              json: body
      };

      return request(edgeCreateOpts).then(function (body) {
        // console.log('################ Create Issue Edge result: %s', JSON.stringify( body));
        return body.result;
      }).catch(function (err) {
        console.log('################ Create Issue Edge error: params %s', JSON.stringify( body));
        console.log('################ Create Issue Edge error: edgeCreateOpts %s', JSON.stringify( edgeCreateOpts));
        console.log('################ Create Issue Edge error .result: %s', JSON.stringify( err));
        return err;
      });

    },{concurrency: concurrentRequest});

  }).then(function(updatedEdgeDocs){
    var t2 = process.hrtime(hrstart);
    console.log("API:loadIssuesData: Issues edges created in Graph:  " + gName + " in " + (t2[0]) + " seconds.");

    console.log('Issues Updated successfully in Graph DB');
  }).catch(function(err) {
    console.log('loadIssuesData:something went wrong', err);
    return err.message;
  });

  return "Load Issues Data Request Sent";

}
// END: Load Edges data from Cloudant

// START: Internal methods
function iCreateGraph(graphName){
  console.log("graphName=" + graphName);
  var graphCreateOpts = {
          method: 'POST',
          headers: {'Authorization': sessionToken},
          uri: baseURL + '/_graphs' + '/' + gName,
          json: true
  };
  // console.log("graphCreateOpts=" + graphCreateOpts);
  return request(graphCreateOpts).then(function (body) {
      apiURL = body.dbUrl; //Update apiURL to use new graph
      return apiURL;
  }).catch(function (err) {
    return err;
  });
  // return "Request to creategraph submitted successfully";
}


function iCreateVertex(graphName, data){
  // console.log('################ iCreateVertex:data: %s', JSON.stringify( data));
  var body = {
    'label': data.label,
    'properties': {
        'name': data.name,
        'type': data.label,
        'pid': data._id,
        'rev': data._rev
    }
  };
  var vertexCreateOpts = {
          method: 'POST',
          headers: {'Authorization': sessionToken},
          uri: baseURL + '/' + gName + '/vertices',
          json: body
  };

  return request(vertexCreateOpts).then(function (body) {
    // console.log('################ body.result: %s', JSON.stringify( body.result));
    return body.result;
  }).catch(function (err) {
    console.log("################ iCreateVertex: ERRORRRRRR data: " + JSON.stringify( body) );
    console.log('################ iCreateVertex: ERRORRRRRR: %s', JSON.stringify( err));
    return err;
  });

  // return "Request to create single vertex submitted successfully";
}


// Function to update all the vertext documents with the graph id
function iUpdateVertexesInCloudant(row){

  // console.log('iUpdateVertexesInCloudant:row:', JSON.stringify(row));
  var gId = row.data[0].id;
  var cId = row.data[0].properties.pid[0].value;
  var cRev = row.data[0].properties.rev[0].value;

  // read the vertex document
  var readDocPromise = db_vertexes.get(cId);

  return readDocPromise.then(function(doc){
    // console.log('getttt: %s', JSON.stringify(doc));
    doc.gid=gId;
    // update the vertex documents with all the graph id's
    var updateDocPromise = db_vertexes.insert(doc);
    return updateDocPromise.then(function (body) {
        // console.log('iUpdateVertexes id: %s', JSON.stringify(body));
        return body;
    }).catch(function (err) {
      console.log('iUpdateVertexesInCloudant:Update Doc: something went wrong', err);
      return err;
    });
  }).catch(function(err) {
    console.log('iUpdateVertexesInCloudant:GET Doc: something went wrong', err);
    return err;
  });

}

// Function to update all the vertext documents with the graph id
function iUpdateIssuesInCloudant(row){

  // console.log('iUpdateIssuesInCloudant:row:', JSON.stringify(row));
  var gId = row.data[0].id;
  var cId = row.data[0].properties.pid[0].value;

  // read the vertex document
  var readDocPromise = db_issuelist.find({selector:{type:'issue', month_id:cId}});

  return readDocPromise.then(function(issueArr){
    var updateDocPromiseArr = [];
    for (var i = 0; i < issueArr.docs.length; i++) {
      var doc = issueArr.docs[i];
      doc.g_month_id = gId;
      var updateDocPromise = db_issuelist.insert(doc);
      updateDocPromiseArr.push(updateDocPromise);
    }

   return updateDocPromiseArr;
  }).catch(function(err) {
    console.log('iUpdateIssuesInCloudant:GET Doc: something went wrong', err);
    return err;
  });

}


function iExecuteSequentially(promises) {
  var result = Promise.resolve();
  promises.forEach(function (promise) {
    result = result.then(promise);
  });
  return result;
}

function iEdgePromiseFactory(doc) {
  // console.log('edgePromiseFactory: doc:' + JSON.stringify(doc));
  return new Promise(function (resolve, reject) {
    db_edges.insert(doc, function (err, body) {
      // console.log('edgePromiseFactory: err: ' + err + 'body:' + JSON.stringify(body));
      if (err) {
        return reject(err);
      }
      resolve(body);
    });
  });
}

function iCreateEdge(graphName, data){
  // console.log("iCreateEdge: src id:" + data.gSrcId + ": target id:" + data.gTgtId + "label:" + data.label);
  // ,
  // 'rev': data._rev
  var body = {
    'label': data.label,
    'outV': data.gSrcId,
    'inV': data.gTgtId
  };

  // ,
  // 'multiplicity': data.multiplicity

  var edgeCreateOpts = {
          method: 'POST',
          headers: {'Authorization': sessionToken},
          uri: baseURL + '/' + gName + '/edges',
          json: body
  };


  return request(edgeCreateOpts).then(function (body) {
    // console.log('################ Create Edge result: %s', JSON.stringify( body));
    return body.result;
  }).catch(function (err) {
    console.log('################ Create Edge error: params %s', JSON.stringify( body));
    console.log('################ Create Edge error: edgeCreateOpts %s', JSON.stringify( edgeCreateOpts));
    console.log('################ Create Edge error .result: %s', JSON.stringify( err));
    return err;
  });

  // return "Request to create single vertex submitted successfully";
}

function iCreateIssue(graphName, data){

  // refactor later to use a common createVertex method
  var vertexBody = {
    'label': data.type,
    "properties": {
      "timely_response": data.timely_response,
      "zip_code": data.zip_code,
      "day": data.day,
      "issue": data.issue,
      // "sub_issue": data.sub_issue,
      "name": data._id,
      "g_month_id": data.g_month_id,
      "received_date": data.received_date
    }
  };

  var vertexCreateOpts = {
          method: 'POST',
          headers: {'Authorization': sessionToken},
          uri: baseURL + '/' + gName + '/vertices',
          json: vertexBody
  };

  return request(vertexCreateOpts).then(function (body) {
    // console.log('################ body.result: %s', JSON.stringify( body.result));
    return body.result;
  }).catch(function (err) {
    console.log("################ iCreateIssue: ERRORRRRRR data: " + JSON.stringify( vertexBody) );
    console.log('################ iCreateIssue: ERRORRRRRR: %s', JSON.stringify( err));
    return err;
  });

  // return "Request to create single vertex submitted successfully";
}


// END: Internal method

function getSampleVertexes(){
  var sampleVertexes = [{"data":[{"id":81924176,"label":"vertex","type":"vertex","properties":{"timely_response":[{"id":"215rm2-1crx3k-27t1","value":"Yes"}],"issue":[{"id":"215s0a-1crx3k-28lh","value":"Billing statement"}],"month_id":[{"id":"215sei-1crx3k-29dx","value":"7d72f318aa305635fdc97be6986912c9"}],"name":[{"id":"215ssq-1crx3k-sl","value":"0fd172e3f6106202abb4181e328ebc5e"}],"day":[{"id":"215t6y-1crx3k-2a6d","value":29}],"zip_code":[{"id":"215tl6-1crx3k-2ayt","value":"45247"}]}}],"meta":{}},{"data":[{"id":4200,"label":"vertex","type":"vertex","properties":{"timely_response":[{"id":"st-38o-27t1","value":"Yes"}],"issue":[{"id":"171-38o-28lh","value":"Cont'd attempts collect debt not owed"}],"month_id":[{"id":"1l9-38o-29dx","value":"7d72f318aa305635fdc97be6986912c9"}],"name":[{"id":"1zh-38o-sl","value":"0fd172e3f6106202abb4181e328ec123"}],"day":[{"id":"2dp-38o-2a6d","value":29}],"zip_code":[{"id":"2rx-38o-2ayt","value":"32818"}]}}],"meta":{}},{"data":[{"id":81924224,"label":"vertex","type":"vertex","properties":{"timely_response":[{"id":"215rm8-1crx4w-27t1","value":"Yes"}],"issue":[{"id":"215s0g-1crx4w-28lh","value":"Cont'd attempts collect debt not owed"}],"month_id":[{"id":"215seo-1crx4w-29dx","value":"7d72f318aa305635fdc97be6986912c9"}],"name":[{"id":"215ssw-1crx4w-sl","value":"0fd172e3f6106202abb4181e328ec4f4"}],"day":[{"id":"215t74-1crx4w-2a6d","value":29}],"zip_code":[{"id":"215tlc-1crx4w-2ayt","value":"20147"}]}}],"meta":{}},{"data":[{"id":4240,"label":"vertex","type":"vertex","properties":{"timely_response":[{"id":"sy-39s-27t1","value":"Yes"}],"issue":[{"id":"176-39s-28lh","value":"Deposits and withdrawals"}],"month_id":[{"id":"1le-39s-29dx","value":"7d72f318aa305635fdc97be6986912c9"}],"name":[{"id":"1zm-39s-sl","value":"0fd172e3f6106202abb4181e328ec5b4"}],"day":[{"id":"2du-39s-2a6d","value":29}],"zip_code":[{"id":"2s2-39s-2ayt","value":"75025"}]}}],"meta":{}},{"data":[{"id":4208,"label":"vertex","type":"vertex","properties":{"timely_response":[{"id":"su-38w-27t1","value":"Yes"}],"issue":[{"id":"172-38w-28lh","value":"Loan servicing, payments, escrow account"}],"month_id":[{"id":"1la-38w-29dx","value":"7d72f318aa305635fdc97be6986912c9"}],"name":[{"id":"1zi-38w-sl","value":"0fd172e3f6106202abb4181e328ec627"}],"day":[{"id":"2dq-38w-2a6d","value":29}],"zip_code":[{"id":"2ry-38w-2ayt","value":"6106"}]}}],"meta":{}},{"data":[{"id":40964344,"label":"vertex","type":"vertex","properties":{"timely_response":[{"id":"odxr3-oe0ag-27t1","value":"Yes"}],"issue":[{"id":"ody5b-oe0ag-28lh","value":"Deposits and withdrawals"}],"month_id":[{"id":"odyjj-oe0ag-29dx","value":"7d72f318aa305635fdc97be6986912c9"}],"name":[{"id":"odyxr-oe0ag-sl","value":"0fd172e3f6106202abb4181e328ed391"}],"day":[{"id":"odzbz-oe0ag-2a6d","value":29}],"zip_code":[{"id":"odzq7-oe0ag-2ayt","value":"30084"}]}}],"meta":{}},{"data":[{"id":40964120,"label":"vertex","type":"vertex","properties":{"timely_response":[{"id":"215rlv-oe048-27t1","value":"Yes"}],"issue":[{"id":"215s03-oe048-28lh","value":"Account opening, closing, or management"}],"month_id":[{"id":"215seb-oe048-29dx","value":"7d72f318aa305635fdc97be6986912c9"}],"name":[{"id":"215ssj-oe048-sl","value":"0fd172e3f6106202abb4181e328ed5f5"}],"day":[{"id":"215t6r-oe048-2a6d","value":29}],"zip_code":[{"id":"215tkz-oe048-2ayt","value":"10065"}]}}],"meta":{}},{"data":[{"id":40964312,"label":"vertex","type":"vertex","properties":{"timely_response":[{"id":"odxqz-oe09k-27t1","value":"Yes"}],"issue":[{"id":"ody57-oe09k-28lh","value":"Using a debit or ATM card"}],"month_id":[{"id":"odyjf-oe09k-29dx","value":"7d72f318aa305635fdc97be6986912c9"}],"name":[{"id":"odyxn-oe09k-sl","value":"0fd172e3f6106202abb4181e328ed802"}],"day":[{"id":"odzbv-oe09k-2a6d","value":29}],"zip_code":[{"id":"odzq3-oe09k-2ayt","value":"95992"}]}}],"meta":{}},{"data":[{"id":81924272,"label":"vertex","type":"vertex","properties":{"timely_response":[{"id":"215rme-1crx68-27t1","value":"Yes"}],"issue":[{"id":"215s0m-1crx68-28lh","value":"Managing the loan or lease"}],"month_id":[{"id":"215seu-1crx68-29dx","value":"7d72f318aa305635fdc97be6986912c9"}],"name":[{"id":"215st2-1crx68-sl","value":"0fd172e3f6106202abb4181e328ee3d4"}],"day":[{"id":"215t7a-1crx68-2a6d","value":29}],"zip_code":[{"id":"215tli-1crx68-2ayt","value":"24540"}]}}],"meta":{}}];
  // var label =  data.properties.type;
  // var name = data.properties.name;
  // var pid =  data._id;
  // var rev = data._rev;

  return sampleVertexes;

  // {"data":[{"id":4312,"label":label,"type":"vertex","properties":{"rev":[{"id":name,"value":name}],"name":[{"id":"5y3-3bs-sl","value":"Consumer Loan"}],"pid":[{"id":pid,"value":pid}]}}],"meta":{}}
}


// module.exports.createSession=createSession;
module.exports.createGraph=createGraph;
module.exports.deleteGraph=deleteGraph;
module.exports.createSchema=createSchema;
// module.exports.startConsumer=startConsumer;
// module.exports.stopConsumer=stopConsumer;
module.exports.loadVertexData=loadVertexData;
module.exports.prepareEdgesData=prepareEdgesData;
module.exports.loadEdgesData=loadEdgesData;
module.exports.prepareIssuesData=prepareIssuesData;
module.exports.loadIssuesData=loadIssuesData;
