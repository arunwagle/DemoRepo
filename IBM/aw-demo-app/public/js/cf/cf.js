'use strict';


$(document).ready(function() {

  $('#createGraphButton').click(function() {
    console.log('Clicked create graph button' );
    var graphName = $('#ccGraphName').val().trim();
    // console.log('CC graphName=' + graphName);

    createGraph(graphName);

  });

  $('#deleteGraphButton').click(function() {
    console.log('Clicked delete graph button' );
    deleteGraphButton();
  });


  $('#createGraphSchemaButton').click(function() {
    console.log('Clicked create schema button' );
    var graphId = $('#ccGraphId').val().trim();
    console.log('CC graphId=' + graphId);

    createSchema(graphId);

  });

  $('#loadVertexButton').click(function() {
    console.log('Clicked load vertext button' );
    loadVertexData();

  });

  $('#prepareEdgesButton').click(function() {
    console.log('Clicked Prepare Edges button' );
    prepareEdgesData();

  });

  $('#loadEdgesButton').click(function() {
    console.log('Clicked load Edges button' );
    loadEdgesData();

  });

  $('#prepareIssuesButton').click(function() {
    console.log('Clicked Prepare Issues button' );
    prepareIssuesData();

  });

  $('#loadIssuesButton').click(function() {
    console.log('Clicked load Issues button' );
    loadIssuesData();

  });


  $('#startConsumerButton').click(function() {
    console.log('Clicked start Kafka Consumer' );
    startConsumer();
  });

  $('#stopConsumerButton').click(function() {
    console.log('Clicked stop Kafka Consumer' );
    stopConsumer();
  });

  // $('#uploadFileButton').click(function() {
  //   console.log('Clicked uploadFileButton' );
  //   uploadFile();
  // });



  function loadVertexData(){
    $.ajax({
      url: "/cf/cc/loadVertexData",
      type: "POST",
      cache: false,
      dataType: "json"
    }).success(function(data) {
      console.log(data);
    }).fail(_error);
  }

  function loadEdgesData(){
    $.ajax({
      url: "/cf/cc/loadEdgesData",
      type: "POST",
      cache: false,
      dataType: "json"
    }).success(function(data) {
      console.log(data);
    }).fail(_error);
  }

  function prepareEdgesData(){
    $.ajax({
      url: "/cf/cc/prepareEdgesData",
      type: "POST",
      cache: false,
      dataType: "json"
    }).success(function(data) {
      console.log(data);
    }).fail(_error);
  }

  function prepareIssuesData(){
    $.ajax({
      url: "/cf/cc/prepareIssuesData",
      type: "POST",
      cache: false,
      dataType: "json"
    }).success(function(data) {
      console.log(data);
    }).fail(_error);
  }

  function loadIssuesData(){
    $.ajax({
      url: "/cf/cc/loadIssuesData",
      type: "POST",
      cache: false,
      dataType: "json"
    }).success(function(data) {
      console.log(data);
    }).fail(_error);
  }

  function deleteGraphButton(){
    $.ajax({
      url: "/cf/cc/deleteGraph",
      type: "POST",
      cache: false,
      dataType: "json"
    }).success(function(data) {
      console.log(data);
    }).fail(_error);
  }

  function startConsumer(){
    $.ajax({
      url: "/cf/cc/startConsumer",
      type: "POST",
      cache: false,
      dataType: "json"
    }).success(function(data) {
      console.log(data);
    }).fail(_error);
  }

  function stopConsumer(){
    $.ajax({
      url: "/cf/cc/stopConsumer",
      type: "POST",
      cache: false,
      dataType: "json"
    }).success(function(data) {
      console.log(data);
    }).fail(_error);
  }

  function createGraph(graphName){
    $.ajax({
      url: "/cf/cc/createGraph",
      type: "POST",
      cache: false,
      contentType: "application/json",
      dataType: "json",
      data: '{"id":' + JSON.stringify(graphName) + '}'
    }).success(function(data) {
      console.log("Create Graph successful" + data);
    }).fail(_error);
  }


  function createSchema(graphId){
    $.ajax({
      url: "/cf/cc/createSchema",
      type: "POST",
      cache: false,
      contentType: "application/json",
      dataType: "json",
      data: '{"id":' + JSON.stringify(graphId) + '}'
    }).success(function(data) {
      console.log("Create Graph successful" + data);
    }).fail(_error);
  }

  function uploadFile(){
    $.ajax({
      url: "/cf/cc/uploadFile",
      type: "POST",
      cache: false,
      dataType: "json"
    }).success(function(data) {
      console.log(data);
    }).fail(_error);
  }

  function _error(error) {
    console.log(error);
  }




});
