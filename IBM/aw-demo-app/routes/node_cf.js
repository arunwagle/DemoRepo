'use strict';

var ibmGraphSvc = require('./node_ibmgraph_async.js');
var ibmObjectStorageSvc = require('./node_objstorage.js');

module.exports = function (app) {

  app.post('/cf/cc/createGraph', function(req, res, next) {
    var graphName = req.body.id;
    console.log("graphName=" + graphName);
    var resp = ibmGraphSvc.createGraph(graphName);
    console.log("resp=" + resp);
    return res.json(resp);
  });

  app.post('/cf/cc/deleteGraph', function(req, res, next) {
    var resp = ibmGraphSvc.deleteGraph();
    console.log("resp=" + resp);
    return res.json(resp);
  });

  app.post('/cf/cc/createSchema', function(req, res, next) {
    var graphId = req.body.id;
    console.log("graphId=" + graphId);
    var resp = ibmGraphSvc.createSchema(graphId);
    console.log("resp=" + resp);
    return res.json(resp);
  });

  app.post('/cf/cc/loadVertexData', function(req, res, next) {
    var resp = ibmGraphSvc.loadVertexData();
    console.log("resp=" + resp);
    return res.json(resp);
  });

  app.post('/cf/cc/prepareEdgesData', function(req, res, next) {
    var resp = ibmGraphSvc.prepareEdgesData();
    console.log("resp=" + resp);
    return res.json(resp);
  });

  app.post('/cf/cc/loadEdgesData', function(req, res, next) {
    var resp = ibmGraphSvc.loadEdgesData();
    console.log("resp=" + resp);
    return res.json(resp);
  });

  app.post('/cf/cc/prepareIssuesData', function(req, res, next) {
    var resp = ibmGraphSvc.prepareIssuesData();
    console.log("resp=" + resp);
    return res.json(resp);
  });

  app.post('/cf/cc/loadIssuesData', function(req, res, next) {
    var resp = ibmGraphSvc.loadIssuesData();
    console.log("resp=" + resp);
    return res.json(resp);
  });

  app.post('/cf/cc/uploadFile', function(req, res, next) {
    var resp = ibmObjectStorageSvc.uploadFile(req, res);
    // console.log("resp=" + resp);
    // return res.json(resp);
  });


  app.post('/cf/cc/startConsumer', function(req, res, next) {
    var resp = ibmGraphSvc.startConsumer();
    console.log("resp=" + resp);
    return res.json(resp);
  });

  app.post('/cf/cc/stopConsumer', function(req, res, next) {
    var resp = ibmGraphSvc.stopConsumer();
    console.log("resp=" + resp);
    return res.json(resp);
  });

  // Consumer Complaints Dash board functions
  app.post('/cf/cc/api/data', function(req, res, next) {
    var graphName = "gtest";
    console.log("graphName=" + graphName);
    // var resp = ibmGraphSvc.createGraph(graphName);
    // console.log("resp=" + resp);
    return res.json(graphName);
  });

  app.post('/cf/cc/api/ts/data', function(req, res, next) {
    var graphName = "gtest1";
    console.log("graphName=" + graphName);
    // var resp = ibmGraphSvc.createGraph(graphName);
    // console.log("resp=" + resp);
    return res.json(graphName);
  });






}
