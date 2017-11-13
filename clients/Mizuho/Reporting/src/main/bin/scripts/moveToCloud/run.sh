set -o errexit

##### Set all variables #######
BLUEMIX_OBJECT_STORAGE_AUTH_URL='https://identity.open.softlayer.com/v3/auth/tokens'

AUTH_PARAMS='{
   "auth":{
      "identity":{
         "methods":[
            "password"
         ],
         "password":{
            "user":{
               "id":"818d185a34e84fefb273a5dd6b119c5e",
               "password":"A[t9w{Kis?v^CAo9"
            }
         }
      },
      "scope":{
         "project":{
            "id":"9f2108032c4e44119f41ba96e9d83883"
         }
      }
   }
}'
TODAYS_DATE=`date +%Y%m%d`
SCRIPT_HOME=/home/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/src/main/bin/scripts/moveToCloud
PROPERTIES_FOLDER=/home/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/properties
CREDENTIAL_FILE=creds-bluemix-object-storage.txt
BATCH_UPLOAD_FILE=batch-csv-upload.txt
TOKEN=$BLUEMIX_OBJECT_STORAGE_TOKEN
CSV_SOURCE_DIR=/home/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/CSVLandingZone
CLOUD_STORAGE_URL=dallas
STORAGE_CONTAINER="MIZ_RPT_DLY_"$TODAYS_DATE
TEMP_DIR=/home/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/temp
LOG_FOLDER=/home/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/logs
UPLOAD_START_TAG="==UPLOADS_START=="
UPLOAD_END_TAG="==UPLOADS_END=="
DELIMITER=";"

######## STEP1: Code to determine OS ###################

lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

OS=`lowercase \`uname\``
KERNEL=`uname -r`
MACH=`uname -m`

if [ "{$OS}" == "windowsnt" ]; then
    OS=windows
elif [ "{$OS}" == "darwin" ]; then
    OS=mac
else
    OS=`uname`
    if [ "${OS}" = "SunOS" ] ; then
        OS=Solaris
        ARCH=`uname -p`
        OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
    elif [ "${OS}" = "AIX" ] ; then
        OSSTR="${OS} `oslevel` (`oslevel -r`)"
    elif [ "${OS}" = "Linux" ] ; then
        if [ -f /etc/redhat-release ] ; then
            DistroBasedOn='RedHat'
            DIST=`cat /etc/redhat-release |sed s/\ release.*//`
            PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
            REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
        elif [ -f /etc/SuSE-release ] ; then
            DistroBasedOn='SuSe'
            PSUEDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
            REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
        elif [ -f /etc/mandrake-release ] ; then
            DistroBasedOn='Mandrake'
            PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
            REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
        elif [ -f /etc/debian_version ] ; then
            DistroBasedOn='Debian'
            DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
            PSUEDONAME=`cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'`
            REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
        fi
        if [ -f /etc/UnitedLinux-release ] ; then
            DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
        fi
        OS=`lowercase $OS`
        DistroBasedOn=`lowercase $DistroBasedOn`
        readonly OS
        readonly DIST
        readonly DistroBasedOn
        readonly PSUEDONAME
        readonly REV
        readonly KERNEL
        readonly MACH
    fi

fi

echo Step 1 Complete: Detected $OS

######## END: Code to determine OS ###################

######## STEP2: Code to compute token for accessing Bluemix Object Storage ###################
# response from the API call
BLUEMIX_OBJECT_STORAGE_RES=$(curl -i -H "Content-Type: application/json" -d "$AUTH_PARAMS" $BLUEMIX_OBJECT_STORAGE_AUTH_URL)

responseArr=( $BLUEMIX_OBJECT_STORAGE_RES );

BLUEMIX_OBJECT_STORAGE_TOKEN=''
for i in "${!responseArr[@]}"; do
if [ "${responseArr[$i]}" == "X-Subject-Token:" ] ; then
    BLUEMIX_OBJECT_STORAGE_TOKEN=${responseArr[$i + 1]};
    break;
fi
done

# echo  Step 2 Complete: BLUEMIX_OBJECT_STORAGE_TOKEN = $BLUEMIX_OBJECT_STORAGE_TOKEN

######## END: Code to compute token for accessing Bluemix Object Storage ###################

######## STEP3: Set and replace the variables in the files ###################
### Get list of file names in CSV_SOURCE_DIR amd create a string
for entry in "$CSV_SOURCE_DIR"/*
do
  #csvUploadList="$csvUploadList"$'\r'"$UPLOAD_START_TAG"$'\r'"$entry"$'\r'"$UPLOAD_END_TAG"
  # csvUploadList="$csvUploadList""$entry"$'\r'" "
  fileNameWithoutFolder=$(basename $entry)
  csvUploadList="$csvUploadList$fileNameWithoutFolder$DELIMITER"



done
echo CSV file List printf "$csvUploadList"

#a=$(echo $csvUploadList | sed 's/ /\n/g')
#echo $a

##### Syntax explanation
#sed = Stream EDitor
# -i = in-place (i.e. save back to the original file)
#
# The command string:
#     s = the substitute command
#     original = a regular expression describing the word to replace (or just the word itself)
#     new = the text to replace it with
#     g = global (i.e. replace all and not just the first occurrence)
#
# file.txt = the file name

if [ $OS = mac ]; then
  echo "Mac detected"
  # Replace values in the batch-csv-upload-template.txt
  sed -i '' -- "s,<PLACEHOLDER_CREDENTIALS>,$PROPERTIES_FOLDER/$CREDENTIAL_FILE,g;s,<PLACEHOLDER_SOURCEDIR>,$CSV_SOURCE_DIR,g;s,<PLACEHOLDER_URL>,$CLOUD_STORAGE_URL,g;s,<PLACEHOLDER_CONTAINER>,$STORAGE_CONTAINER,g;s,<PLACEHOLDER_TMPDIR>,$TEMP_DIR,g;s,<PLACEHOLDER_UPLOAD_FILES>,$csvUploadList,g"  $PROPERTIES_FOLDER/$BATCH_UPLOAD_FILE
  # Replace TOKEN value in the creds-bluemix-object-storage-template.txt
  sed -i '' -- "s/<PLACEHOLDER_TOKEN>/$BLUEMIX_OBJECT_STORAGE_TOKEN/g" $PROPERTIES_FOLDER/$CREDENTIAL_FILE
else
  echo "Not Mac detected"
  # Replace values in the batch-csv-upload-template.txt
  sed -i -- "s,<PLACEHOLDER_CREDENTIALS>,$PROPERTIES_FOLDER/$CREDENTIAL_FILE,g;s,<PLACEHOLDER_SOURCEDIR>,$CSV_SOURCE_DIR,g;s,<PLACEHOLDER_URL>,$CLOUD_STORAGE_URL,g;s,<PLACEHOLDER_CONTAINER>,$STORAGE_CONTAINER,g;s,<PLACEHOLDER_TMPDIR>,$TEMP_DIR,g;s,<PLACEHOLDER_UPLOAD_FILES>,$csvUploadList,g"  $PROPERTIES_FOLDER/$BATCH_UPLOAD_FILE
  # Replace TOKEN value in the creds-bluemix-object-storage-template.txt
  sed -i -- "s/<PLACEHOLDER_TOKEN>/$BLUEMIX_OBJECT_STORAGE_TOKEN/g" $PROPERTIES_FOLDER/$CREDENTIAL_FILE
fi

echo  Step 3 Complete: Set and replace the variables in the files

######## END: Set and replace the variables in the files ###################

######## STEP4: Upload files to object storage ###################
cd $SCRIPT_HOME
# Run batch upload
perl moveToCloud.pl -batch $PROPERTIES_FOLDER/$BATCH_UPLOAD_FILE  -debug $LOG_FOLDER/log.txt -yes

# Run single upload
#perl moveToCloud.pl -source ../../data/AssetsImportCompleteSample.csv -target softlayer::dallas::csv_landing_zone::AssetsImportCompleteSample.csv -creds creds-bluemix-object-storage.txt -tmpdir temp -threads 6 -debug log.txt -token -nocompression
######## END: Upload files to object storage ###################
