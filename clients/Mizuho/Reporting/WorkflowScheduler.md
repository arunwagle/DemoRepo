
# Perform the following tasks
- [x] Create "WorkloadScheduler" service from Bluemix Catalog
- [x] Setting up system for hybrid jobs
- [x] Scheduling Hybrid Jobs

### Create "WorkloadScheduler" service from Bluemix Catalog
- Login to Bluemix
- Select "Workflow Scheduler" service from the Bluemix Catalog and create.
- Once the service is provisioned you should see a "Launch" button

### Setting up system for hybrid jobs
- Refer to **"Setup Workload Scheduler for Hybrid Clould"** in [Setup](https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/Reporting/setupdoc.md)
- Following operating systems are supported
  - Linux
  - Windows
  - AIX
  - HP-UX
  - IBM i
### Scheduling Hybrid Jobs
- Launch the Scheduler from the Bluemix services
- Create a new process library
    <img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/WS_ProcessLibrary.png">
- Create a new process
    <img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/WS_Process_1.png">
- Specify Triggers (Schedule)
    <img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/WS_Process_2.png">
- Create Steps
  - a: Create a remote step to run prepare.sh
  - b: Create a remote step to run run.sh. This will upload the CSV to object storage
    <img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/WS_Process_3.png">
    <img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/WS_Process_4.png">  
- Enable the process
