'use strict';

// var skipper = require("skipper");
var skipperSwift = require("skipper-openstack")();
var container = 'csvContainer';

var storageCredentials;

if (process.env.VCAP_SERVICES) {
  var vcapServices = JSON.parse(process.env.VCAP_SERVICES);
  var storageService = 'Object-Storage';
  if (vcapServices[storageService] && vcapServices[storageService].length > 0) {
    storageCredentials = vcapServices[storageService][0].credentials;
    console.log("storageCredentials=" + JSON.stringify(storageCredentials));
    console.log("process.env=" + JSON.stringify(process.env));
    skipperSwift.ensureContainerExists(storageCredentials, container, function (error) {
      if (error) {
        console.log("unable to create default container", container);
      }
      else {
        console.log("ensured default container", container, "exists");
      }
    });
  }
}

var uploadFile=function uploadFile(request, response){
  console.log("#####request.file" + request.file('file'));
  // console.log("#####request.file" + request.file('file'));
  // request.file('file')
  //   .upload({
  //         adapter: require("skipper-openstack"),
  //         credentials: storageCredentials,
  //         container: container
  //       }, function (err, uploadedFiles) {
  //           if (err) {
  //               console.log(err);
  //               // return response.send(err);
  //           }
  //           return response.json({
  //             message: uploadedFiles.length + ' file(s) uploaded successfully!',
  //             files: uploadedFiles
  //           });
  //
  //     });

  return request.file('file')
  .on('error', function onError(err) {
    console.log("Error uploading file");
    return err.message;
  })
  .on('finish', function onSuccess() {
    return "Success";
  })
  .upload({
    adapter: require("skipper-openstack"),
    credentials: storageCredentials,
    container: container
  });

}

module.exports.uploadFile=uploadFile;
