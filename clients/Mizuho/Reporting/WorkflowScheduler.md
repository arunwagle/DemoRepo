
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
- 1: Create a new process library
  
- 2: Create a new process
- 3: Specify Triggers (Schedule)
- 4: Create Steps
  - a: Create a remote step to run prepare.sh
  - b: Create a remote step to run run.sh. This will upload the CSV to object storage
- 5: Enable the process
