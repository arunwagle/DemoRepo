<img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/Mizuho_header.png">

# Business Object & Challenge
Mizuho does not have the means to automatically process and generate reports during the daily reconciliation process. Today it is a manual process capturing data across a multitude of data sources into mostly excel and csv flat files. Data integrity, scalability, and efficiency are lacking in the overall MAI Holdings Report process.

# Architecture

<img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/Mizuho-architecture.png">

# Demo Steps
### High Level Application Flow
- [x] Bulk upload CSV data from on-premise location to Bluemix Object storage. Automate all the above steps using Bluemix Workflow Scheduler 
- [x] Create schema in DB2 Warehouse on cloud from the CSV files
- [x] Move data from Bluemix Object storage to DB2 Warehouse on cloud using IBM DSX
- [x] Generate reports using Cognos Analytics on cloud



#### Pre-requisites
- Refer to [Setup guidelines for this project](setupdoc.md)

#### Move CSV files to Bluemix Object Storage
  Setup the script that will be used to upload the files.  
  - Refer to [Setup the scripts required to upload the files](src/main/bin/scripts/moveToCloud/README.md)  

#### Create DB2 Warehouse on cloud schema from the CSV data files & ### Move data from Bluemix Object Storage to DB2 Warehouse on cloud
- Refer to [Using IBM DSX to design python notebooks to move data from Object Storage and DashDB, schedule jobs](DSX_TODO.md) OR
For simple row,col csv files we can also use
- Refer to [Using Data Connect to design data flow between Object Storage and DashDB, schedule jobs](DataConnect.md)

#### Automate the process 
-Refer to [Use Workflow Scheduler to create jobs to upload CSV files to Object Storage](WorkflowScheduler.md)

#### Create reports using Cognos Analytics.
- Refer to [Using Cognos analytics to generate reports](CognosAnalytics.md)

