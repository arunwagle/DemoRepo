
# moveToCloud script
The purpose of this module is to upload the file to the IBM Bluemix Object Storage. This script is modified from its original download for the purpose of this use case.

You can refer to [moveToCloud readme](https://www.ibm.com/support/knowledgecenter/en/SS6NHC/com.ibm.swg.im.dashdb.doc/learn_how/moveToCloud_readme.html) for details on the script.


# Setup
#### Important files
* prepare.sh : Modify the file to update as per your environment
  - SOURCE_CSV_FOLDER : Source location for all the CSV files on the local system
  
  - CSV_LANDING_ZONE_FOLDER : Landing zone for CSV files from which we move the files to the Object storage
  
  - SOURCE_TEMPLATE_FOLDER : Templates to be used for this upload process. Currently we have 2 templates viz. batch-csv-upload.txt & creds-bluemix-object-storage.txt
  
  - PROPERTIES_FOLDER : Property files required for this upload
  
* run.sh
  - BLUEMIX_OBJECT_STORAGE_AUTH_URL: Your URL for the Bluemix Object Storage
  - AUTH_PARAMS: Your URL for the Bluemix Object Storage
  - SCRIPT_HOME: Location of the scripts folder
  - PROPERTIES_FOLDER: Location of the property files.
  - CREDENTIAL_FILE: Stores dynamically generated token for accessing Bluemix Object storage to be uploaded.
  - BATCH_UPLOAD_FILE: This file stores information for batch uploading the CSV to Bluemix Object Storage. 
  - TOKEN: Token for accessing Bluemix Object storage to be uploaded.
  - CSV_SOURCE_DIR: Location of CSV files to be uploaded to object storage
  - CLOUD_STORAGE_URL: Specify the location of the data center for your object storage (E.g. dallas). this should match with the value in the moveToCloud.pl
  - STORAGE_CONTAINER: Storage container name created in the Bluemix Object Storage
  - TEMP_DIR: Temporary directory used by the script before uploading data to object storage
  - LOG_FOLDER: Log folder location
  - UPLOAD_START_TAG="==UPLOADS_START=="
  - UPLOAD_END_TAG="==UPLOADS_END=="
  - DELIMITER=";"

* moveToCloud.pl


