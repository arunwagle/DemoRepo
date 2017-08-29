set -o errexit

####### Set variables ###########
SOURCE_CSV_FOLDER=/home/arunwagle/Projects/Data/csvsource
CSV_LANDING_ZONE_FOLDER=/home/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/CSVLandingZone
SOURCE_TEMPLATE_FOLDER=/home/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/src/main/resources/templates
PROPERTIES_FOLDER=/home/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/properties
LOGS_FOLDER=/home/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/target/logs
#### STEP1: Clean up files
rm -rf $CSV_LANDING_ZONE_FOLDER/*
rm -rf $PROPERTIES_FOLDER/*

mkdir -p $CSV_LANDING_ZONE_FOLDER
mkdir -p $PROPERTIES_FOLDER
mkdir -p $LOGS_FOLDER

####

######## STEP2: Copy CSV files from "" to target/CSVLandingZone ###################
cp $SOURCE_CSV_FOLDER/*.csv  $CSV_LANDING_ZONE_FOLDER

######## END: Copy CSV files to target/CSVLandingZone ###################


######## STEP3: Copy template files from /resources/template to target/properties ###################
cp $SOURCE_TEMPLATE_FOLDER/*  $PROPERTIES_FOLDER
######## END: Copy template files from /resources/template to target/properties ###################

echo CSV and property files copied successfully
