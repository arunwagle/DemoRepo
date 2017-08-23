
# Perform the following tasks
- [x] Launch Cognos Analytics on cloud.
- [x] Create connections to DB2 Warehouse on cloud
- [x] Create a data module by connecting to DB2 Warehouse on Cloud
- [x] Optional Step- Create a package using IBM Cognos Framework Manager
- [x] Create reports 
- [x] Administration tasks 

### Launch Cognos Analytics on cloud.
- Signup for trial or if you already have purchased CA on cloud, login using the userid and password.

### Create connections to DB2 Warehouse on cloud
- Select "Manage" > "Data Server Connections" from left hand side menu 
- Create DB2 Warehouse on Cloud Connection. 
  - You will need a valid Bluemix account and a service for DB2 Warehouse on Cloud service created.
  - For credentials while creating connections, refer to the Bluemix panel for the DB2 Warehouse service.     
- Test the connection.
- Load the metadata for the schema you want to use for this usecase.
<img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/CA_DataConnections.png">

### Create a data module by connecting to DB2 Warehouse on Cloud
- Select "My Content" option form the menu on left side. Create folder/subfolders **MortgageAssets**. 
- Select "New" > "Data Servers" > "DB2WarehouseDataServerConnection"  > "Your Schema" and click on "Start" 
<img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/CA_DataConnections_1.png">
- Select the "Your Schema" > "Table name" (E.g. Mortgage Report New) and drag to the "New Data Module" panel.
- Select "Save" from the top left menu to save the data module. Save the data module in the folder create in "My Content" above.

### Optional Step- Create a package using IBM Cognos Framework Manager
- Using IBM Cognos Framework Manager, create packages that can be used to generate reports. 
- The main idea is to model your business using the concepts of Query Subjects, Dimensions and fact tables.
- You can design your model with access to specific group of users. For e.g CEO, CFO can see a different sets of data than BA.
- This will be mainly used to design your OLAP kind queries for reporting.
- Refer to [IBM Cognos Framework Manager](http://public.dhe.ibm.com/software/data/cognos/documentation/docs/en/11.0.0/ug_fm.pdf )for more details.
- High Level Steps
  - [x] Create new project
  - [x] Connect to data source (in this case DB2Warehouse on cloud)
  - [x] Load meta data. By defult it will create Query Subjects on the schema selected. 
  - [x] Create new query subjects, calculations, dimensions etc required for your business
  - [x] Publish the package
  - [x] Create reports

- Fig1 : 
  <img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/CA_Frameworkmanager_step0.png">

- Fig2 : 
  <img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/CA_Frameworkmanager_step1.png">

### Create reports 
- Once the data is setup, you are ready to create reports
- Some examples of common reports are "Crosstab reports", "Visualizations", "Maps", "Active Reports"
- Refer to docs [IBM Cognos Analytics - Reporting](http://public.dhe.ibm.com/software/data/cognos/documentation/docs/en/11.0.0/ug_cr_rptstd.pdf)
- In this example we have ceated 3 types of reports "Crosstab", "Visualization", "List Report"
- Fig1 : Cross tab report

- Fig2: Visualization reports


### Administration/management tasks
Few useful admin tasks.
- Subscribing to specific reports
- Notifications panel
- Scheduling reports to be emailed, run at specific times
- User management
- Fig1: Notifications
  <img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/CA_Notifications.png">
- Fig2: Scheduling
<img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Mizuho/images/CA_Subscribe.png">


