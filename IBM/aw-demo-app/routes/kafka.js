// var kafka;
// var topicName = "topic_cf_cc_small";
// var kafkaRestAPIURL;
// var kafkaConsumerGroup = "console-consumer-grp-" + topicName;
// var fromBeginning = true;
// var consumed = 0;
// var consumerConfig = {
//     "format": "binary"
// };
// if (fromBeginning) {
//     consumerConfig['auto.offset.reset'] = 'largest';
// }



// // START: Start Consumer
// var kafka_consumer_instance;
// var startConsumer=function startConsumer(){
//   kafka.consumer(kafkaConsumerGroup).join(consumerConfig, function(err, consumer_instance) {
//       if (err) return console.log("Failed to create instance in consumer group: " + err);
//       kafka_consumer_instance = consumer_instance;
//       console.log("kafka_consumer_instance: " + consumer_instance.toString());
//       console.log("Consumer instance initialized: " + consumer_instance.toString());
//       var stream = consumer_instance.subscribe(topicName);
//       stream.on('data', function(msgs) {
//           for(var i = 0; i < msgs.length; i++) {
//               if (consumerConfig.format == "binary") {
//                   // Messages keys (if available) and values are decoded from base64 into Buffers. You'll need to decode based
//                   // on whatever serialization format you used. By default here, we just try to decode to text.
//                   console.log(msgs[i].value.toString('utf8'));
//                   // Also available: msgs[i].key, msgs[i].partition
//               } else {
//                   console.log(JSON.stringify(msgs[i].value));
//               }
//           }
//
//           consumed += msgs.length;
//           // if (messageLimit !== undefined && consumed >= messageLimit)
//           //     consumer_instance.shutdown(logShutdown);
//       });
//       stream.on('error', function(err) {
//           console.log("Consumer instance reported an error: " + err);
//           console.log("Attempting to shut down consumer instance...");
//           consumer_instance.shutdown(logShutdown);
//       });
//       stream.on('end', function() {
//           console.log("Consumer stream closed.");
//       });
//
//       // Events are also emitted by the parent consumer_instance, so you can either consume individual streams separately
//       // or multiple streams with one callback. Here we'll just demonstrate the 'end' event.
//       consumer_instance.on('end', function() {
//           console.log("Consumer instance closed.");
//       });
//
//       // Also trigger clean shutdown on Ctrl-C
//       process.on('SIGINT', function() {
//           console.log("Attempting to shut down consumer instance...");
//           consumer_instance.shutdown(logShutdown);
//       });
//
//   });
//   return "Request to startConsumer submitted";
// }
// // END: Start Consumer
//
// // START: Start Consumer
// var stopConsumer=function stopConsumer(){
//   if(kafka_consumer_instance !== undefined){
//     kafka_consumer_instance.shutdown(logShutdown);
//   }
//   return "Request to stopConsumer submitted";
// }
//
// function logShutdown(err) {
//     if (err)
//         console.log("Error while shutting down: " + err);
//     else
//         console.log("Shutdown cleanly.");
// }

// END: Start Consumer


// function iSaveToCloudant(row){
//   if(typeof(row[0].error) !== 'undefined'){
//       console.log("iSaveToCloudant: error: " + JSON.stringify(row));
//       return false;
//   }
//
//   return db.insert(row).then(function (body) {
//       console.log('iSaveToCloudant id: %s', JSON.stringify(body));
//       return body;
//   }).catch(function (err) {
//     return err.message;
//   });
// }
