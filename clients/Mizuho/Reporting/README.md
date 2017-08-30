<img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/Mizuho_header.png">

# Business Object & Challenge
Mizuho does not have the means to automatically process and generate reports during the daily reconciliation process. Today it is a manual process capturing data across a multitude of data sources into mostly excel and csv flat files. Data integrity, scalability, and efficiency are lacking in the overall MAI Holdings Report process.

# Architecture

<img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/Mizuho-architecture.png">

# Demo Steps
### Setup Process
- Refer to [Setup guidelines for this project](setupdoc.md)
### Move CSV files to object storage
  This is a 2 steps process. The first step is to setup the script that will be used to upload the files. The second step will be to configure a scheduled job to run the script
  - Refer to [Setup the scripts required to upload the files](src/main/bin/scripts/moveToCloud/README.md)
  - Refer to [Use Workflow Scheduler to create jobs to upload CSV files to Object Storage](WorkflowScheduler.md)
### Create DashDB tables from the Object Storage CSV files using Data Connect
- Refer to [Using Data Connect to design data flow between Object Storage and DashDB, schedule jobs](DataConnect.md)
### Create reports using Cognos Analytics.
- Refer to [Using Cognos analytics to generate reports](CognosAnalytics.md)

