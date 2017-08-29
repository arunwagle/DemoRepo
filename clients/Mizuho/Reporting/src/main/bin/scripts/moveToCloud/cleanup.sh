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

responseArr=( $BLUEMIX_OBJECT_STORAGE_RES );

BLUEMIX_OBJECT_STORAGE_TOKEN=''
for i in "${!responseArr[@]}"; do
if [ "${responseArr[$i]}" == "X-Subject-Token:" ] ; then
    BLUEMIX_OBJECT_STORAGE_TOKEN=${responseArr[$i + 1]};
    break;
fi
done

echo BLUEMIX_OBJECT_STORAGE_TOKEN=$BLUEMIX_OBJECT_STORAGE_TOKEN
# Copy object to csv_processed_landing_zone folder
# Step1: create container by DATE
TODAYS_DATE=`date +%Y-%m-%d`
curl -i https://dal.objectstorage.open.softlayer.com/v1/AUTH_9f2108032c4e44119f41ba96e9d83883/csv_processed_$TODAYS_DATE -X PUT -H "Content-Length: 0" -H "X-Auth-Token: $BLUEMIX_OBJECT_STORAGE_TOKEN"

# Step2: Copy files from csv_landing_zone to csv_processed_landing_zone/$TODAYS_DATE
curl -i https://dal.objectstorage.open.softlayer.com/v1/AUTH_9f2108032c4e44119f41ba96e9d83883/csv_landing_zone/FL_insurance_sample.csv -X COPY -H "X-Auth-Token: $BLUEMIX_OBJECT_STORAGE_TOKEN" -H "Destination: csv_processed_$TODAYS_DATE/FL_insurance_sample.csv"

# Delete files from csv_landing_zone
curl -i https://dal.objectstorage.open.softlayer.com/v1/AUTH_9f2108032c4e44119f41ba96e9d83883/csv_landing_zone/FL_insurance_sample.csv -X DELETE -H "X-Auth-Token: $BLUEMIX_OBJECT_STORAGE_TOKEN"
