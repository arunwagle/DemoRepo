#!/bin/bash

cd IBM/aw-demo-app

bluemix api https://api.ng.bluemix.net

bluemix login -u arun.wagle@ibm.com -o OSNorth.Arun.Wagle.Org -s Development -p sourceCode0520

bluemix app push aw-demo-app

echo Finished deploying aw-demo-app
