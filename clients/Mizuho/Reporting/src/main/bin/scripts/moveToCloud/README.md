
# moveToCloud module
The purpose of this module is to upload the file to the IBM Bluemix Object Storage. This script is modified from its original download for the purpose of this use case.

You can refer to [moveToCloud readme](https://www.ibm.com/support/knowledgecenter/en/SS6NHC/com.ibm.swg.im.dashdb.doc/learn_how/moveToCloud_readme.html) for details on the script.

# Run
All data needed to run are generated under the target folder. 

**Note: Please refer to setup section before running the script.**

* Run ./prepare.sh. This prepares the environmen
* Run ./run.sh. The script does the following
  - STEP1: Code to determine OS. Currently tested only for MacOS & CentOS.
  - STEP2: Code to compute token for accessing Bluemix Object Storage
  - STEP3: Set and replace the variables in the files
  - STEP4: Upload files to object storage by running the moveToCloud.pl


# Setup
#### Important files

Modify the file to update as per your environment

* prepare.sh
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
  - DELIMITER=";" ** if you change this then the code needs to be changed **

* moveToCloud.pl: Perl script to upload the data to object storage. 
  #### Description
  The script requires 2 files for it to work viz. batch-csv-upload.txt & creds-bluemix-object-storage.txt. These files are generated a part of running the ** prepare.sh ** and ** run.sh **. The files above are generated using the templates, refer to files in SOURCE_TEMPLATE_FOLDER location.  

  - search and replace "softlayer_urls". For e.g. I modified **'dallas'** to point to my instance of object storage "https://dal.objectstorage.open.softlayer.com/v1/AUTH_xxxxxx"
  - The original script has been modified to add **$delimiter** code.
  

  



