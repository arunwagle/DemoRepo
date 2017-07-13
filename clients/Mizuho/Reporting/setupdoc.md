
# Setup Workload Scheduler for Hybrid Clould 
- Login to Bluemix & Add Workflow Scheduler service.
- Download agent to be installed on your premise. "Downloads" link is available when you select the servoce created in the above step. 
  - For Linux download agent for Linux 64-bit (Intel platform)
  - Install and setup the agent. Refer to https://www.ibm.com/support/knowledgecenter/SS4J4Z_1.0.0/com.ibm.tivoli.wasaas.doc_1.0.0/distr/src_pi/awssaaspiinstul.htm
  - The agent should be installed on each customer machine which needs to be used for scheduling. The machine should have access to the internet as the agent needs to communicate with Bluemix Workflow Scheduler.
  ```
  Install steps for Linux 64 bit
  
  1. For Linux 64-bit: temporary disk space 250 MB, installation directory space inst_dir 470 MB
  2. If you did not already download the agent installation files, go to the Downloads section on the Your subscription page
  3. For Linux 64 bit, extract the SCWA-SaaS_LINUX_X86_64.zip
  4. When the extraction completes, the following directory structure is created in the SCWA-SaaS directory on your computer
  5. From a shell on the computer on which you want to install the product, log on as root.
      ./installAgent.sh -new [-uname user_name] -acceptlicense yes
      where uname user_name
      - If you logged in as the root user, it is the name of the user for which the agent is installed. This is the user you created in the previous step. Do not confuse this name with the user performing the installation logged on as root, or with the user name you received by email when you requested your subscription.
      - If you logged in as another user, you do not need to specify this keyword as it automatically takes the login name.
      
  6. The agent is installed in home_dir/TWA directory or /opt/IBM/TWA_user_name. 
  7. Ensure that the directory permission of home_dir is set to 755 and that your login owns it
  
  For other environments, refer to https://www.ibm.com/support/knowledgecenter/SS4J4Z_1.0.0/com.ibm.tivoli.wasaas.doc_1.0.0/distr/src_pi/awssaaspi_installing.html
   
  ```
- Once the installation of agent is complete, launch the scheduler from Bluemix Console and create jobs. You should see the us the agent created in the above step. This can now be used to schedule jobs on the customer machine from the Workflow Scheduler Agent.


# Setup DataConnect in Bluemix
- Login to Bluemix & Add Data Connect Service.
- Launch the Data Connect Application and learn how to create source and target connections, activities, Design Flow
- Design Flow helps you to map source to target at a column level.

# Setup DashDB in Bluemix
- Login to Bluemix & Add Dash DB Service.
- Learn how to run SQL, create tables 

# Setup Object Storage in Bluemix
- Login to Bluemix & Add Object Storage  Service.
- Learn how to create containers and upload files to the containers. 

# Setup Cognos Analytics
- Once you have subscription to Cognos Analytics on Cloud,login to https://www.ibm.com/analytics/us/en/technology/products/cognos-analytics/
