
# Perform the following tasks
- [x] Create "WorkloadScheduler" service from Bluemix Catalog
- [x] Setting up system for hybrid jobs
- [x] Scheduling Hybrid Jobs
  - [x] Create prepare step
  - [x] Create run step
  - [x] Create REST service step
  

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
- High level process to create Steps
  Note: The order of the steps is important as they need to get executed in a particular order.
  - a: Step1: Create prepare step    
    ```
    Create a remote step to run prepare.sh
    
    Step: Run Remote Command(Select from drop down)
    Agent: Select the agent configured on the on-premise machine
    Command: Select the script prepare.sh
    E.g. /home/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/src/main/bin/scripts/moveToCloud/prepare.sh
    Username: Specify the username of the user on the local machine which was used to install the hybrid agent
    Password: Specify the password of the user on the local machine which was used to install the hybrid agent
    Server: localhost (This is the same machine on which the agent is running)
    ``` 
  - b: Step2: Create run step
    ```
    Create a remote step to run run.sh. This will upload the CSV to object storage
    
    Step: Run Remote Command(Select from drop down)
    Agent: Select the agent configured on the on-premise machine
    Command: Select the script prepare.sh
    E.g. /home/arunwagle/Projects/DemoRepo/clients/Mizuho/Reporting/src/main/bin/scripts/moveToCloud/run.sh
    Username: Specify the username of the user on the local machine which was used to install the hybrid agent
    Password: Specify the password of the user on the local machine which was used to install the hybrid agent
    Server: localhost (This is the same machine on which the agent is running)
    ```
  - c: Step3: Create RESTservice step
    ```
    Create a remote step to create a RESTful service to Data Connect. This will run the acitivity created in DataConnect to upload data from object storage to DB2 Warehouse on cloud 
    
    Step: RESTful (Select from drop down)
    Agent: Select the cloud agent 
    
    Authentication: 
      Username: Select the userid from the credential section in Bluemix for Data Connect service
      Password: Select the password from the credential section in Bluemix for Data Connect service
    
    Action: 
      Service URI: https://dataworks-api.services.us-south.bluemix.net:443/ibm/dataworks/dc/v1/activities/9ac4c169c8e822bede229cf2474a0cbc/activityRuns
    Note: Make sure the activity id should be for the activity created. To find activity id, you can run the following
    curl --request GET --url 'https://service.binding.url/ibm/dataworks/dc/v1/activities' header 'accept: application/json;charset=utf-8' and select the id for the activity you created in data connect.
      Method: POST
    Advanced: 
      Accept: application/json;charset=utf-8
      
    ```
<img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/WS_Process_3.png">
<img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/WS_Process_4.png">  
- Enable the process


