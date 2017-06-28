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

# response from the API call
BLUEMIX_OBJECT_STORAGE_RES=$(curl -i -H "Content-Type: application/json" -d "$AUTH_PARAMS" $BLUEMIX_OBJECT_STORAGE_AUTH_URL)

# Extract the token from the response
head=true
while read -r line; do
    if $head; then
        if [[ $line = $'\r' ]]; then
        head=false
    else
        str=$(echo $line | grep "X-Subject-Token:" | awk '{print $2}');
        if [ ! -z "$str" -a "$str"!=" " ]; then
            BLUEMIX_OBJECT_STORAGE_TOKEN=$str
        fi
    fi
    else
        body="$body"$'\n'"$line"
    fi
done < <(echo "$BLUEMIX_OBJECT_STORAGE_RES")

echo  Step 2 Complete: BLUEMIX_OBJECT_STORAGE_TOKEN = $BLUEMIX_OBJECT_STORAGE_TOKEN

######## END: Code to compute token for accessing Bluemix Object Storage ###################

######## STEP3: Set and replace the variables in the files ###################
PROPERTIES_FOLDER=/Users/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/properties
CREDENTIAL_FILE=creds-bluemix-object-storage.txt
BATCH_UPLOAD_FILE=batch-csv-upload-template.txt
TOKEN=$BLUEMIX_OBJECT_STORAGE_TOKEN
CSV_SOURCE_DIR=/Users/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/CSVLandingZone
CLOUD_STORAGE_URL=dallas
STORAGE_CONTAINER=csv_landing_zone
TEMP_DIR=/Users/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/temp


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

if [ OS=mac ]; then
  # Replace values in the batch-csv-upload-template.txt
  sed -i '' -- "s,<PLACEHOLDER_CREDENTIALS>,$PROPERTIES_FOLDER/$CREDENTIAL_FILE,g;s,<PLACEHOLDER_SOURCEDIR>,$CSV_SOURCE_DIR,g;s,<PLACEHOLDER_URL>,$CLOUD_STORAGE_URL,g;s,<PLACEHOLDER_CONTAINER>,$STORAGE_CONTAINER,g;s,<PLACEHOLDER_TMPDIR>,$TEMP_DIR,g"  $PROPERTIES_FOLDER/$BATCH_UPLOAD_FILE
  # Replace TOKEN value in the creds-bluemix-object-storage-template.txt
  sed -i '' -- "s/<PLACEHOLDER_TOKEN>/$token/g" $PROPERTIES_FOLDER/$CREDENTIAL_FILE
else
  # Replace values in the batch-csv-upload-template.txt
  sed -i -- "s,<PLACEHOLDER_CREDENTIALS>,$PROPERTIES_FOLDER/$CREDENTIAL_FILE,g;s,<PLACEHOLDER_SOURCEDIR>,$CSV_SOURCE_DIR,g;s,<PLACEHOLDER_URL>,$CLOUD_STORAGE_URL,g;s,<PLACEHOLDER_CONTAINER>,$STORAGE_CONTAINER,g;s,<PLACEHOLDER_TMPDIR>,$TEMP_DIR,g"  $PROPERTIES_FOLDER/$BATCH_UPLOAD_FILE
  # Replace TOKEN value in the creds-bluemix-object-storage-template.txt
  sed -i -- "s/<PLACEHOLDER_TOKEN>/$token/g" $PROPERTIES_FOLDER/$CREDENTIAL_FILE
fi

echo  Step 3 Complete: Set and replace the variables in the files

######## END: Set and replace the variables in the files ###################

######## STEP4: Code to get token for accessing Bluemix Object Storage ###################




######## END: Code to get token for accessing Bluemix Object Storage ###################
