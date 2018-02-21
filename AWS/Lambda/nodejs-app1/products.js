'use strict';

exports.handler = (event, context, callback) => {

    let id = event.pathParameters.product || false;

    console.log('value1 =', event.key1);
    console.log('value2 =', event.key2);
    console.log('value3 =', event.key3);
    console.log('remaining time =', context.getRemainingTimeInMillis());
    console.log('functionName =', context.functionName);
    console.log('AWSrequestID =', context.awsRequestId);
    console.log('logGroupName =', context.logGroupName);
    console.log('logStreamName =', context.logStreamName);
    console.log('clientContext =', context.clientContext);
    if (typeof context.identity !== 'undefined') {
        console.log('Cognitoidentity ID =', context.identity.cognitoIdentityId);
    }

    switch(event.httpMethod){

        case "GET":

            if(id) {
                callback(null, {body: "This is a READ operation on product ID " + id});
                return;
            }

            callback(null, {body: "This is a LIST operation, return all products"});
            break;

        case "POST":
            callback(null, {body: "This is a CREATE operation"});
            break;

        case "PUT":
            callback(null, {body: "This is an UPDATE operation on product ID " + id});
            break;

        case "DELETE":
            callback(null, {body:"This is a DELETE operation on product ID " + id});
            break;

        default:
            // Send HTTP 501: Not Implemented
            console.log("Error: unsupported HTTP method (" + event.httpMethod + ")");
            callback(null, { statusCode: 501 })

    }

}
