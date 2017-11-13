set -o errexit

####### Set variables ###########
SOURCE_CSV_FOLDER=/Users/arunwagle/Downloads/MAI_Holdings_Source_Files/src
CSV_LANDING_ZONE_FOLDER=/Users/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/CSVLandingZone
SOURCE_TEMPLATE_FOLDER=/Users/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/src/main/resources/templates
PROPERTIES_FOLDER=/Users/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/properties
LOGS_FOLDER=/Users/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/logs
#### STEP1: Clean up files
rm -rf $CSV_LANDING_ZONE_FOLDER/*
rm -rf $PROPERTIES_FOLDER/*

mkdir -p $CSV_LANDING_ZONE_FOLDER
mkdir -p $PROPERTIES_FOLDER
mkdir -p $LOGS_FOLDER

####

######## STEP2: Copy CSV files from "" to target/CSVLandingZone ###################
cp $SOURCE_CSV_FOLDER/*.*  $CSV_LANDING_ZONE_FOLDER

######## END: Copy CSV files to target/CSVLandingZone ###################


######## STEP3: Copy template files from /resources/template to target/properties ###################
cp $SOURCE_TEMPLATE_FOLDER/*  $PROPERTIES_FOLDER
######## END: Copy template files from /resources/template to target/properties ###################

echo CSV and property files copied successfully to $CSV_LANDING_ZONE_FOLDER , $PROPERTIES_FOLDER
