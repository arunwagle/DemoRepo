
# Perform the following tasks
- [x] Launch Cognos Analytics on cloud.
- [x] Create connections to DB2 Warehouse on cloud
- [x] Create a data module by connecting to DB2 Warehouse on Cloud
- [x] Create reports 

### Launch Cognos Analytics on cloud.
- Signup for trial or if you already have purchased CA on cloud, just login using the userid and password.

### Create connections to DB2 Warehouse on cloud
- Select "Manage" > "Data Server Connections" from left hand side menu 
- Create DB2 Warehouse on Cloud Connection. 
  - You will need a valid Bluemix account and a service for DB2 Warehouse on Cloud service created.
  - For credentials while creating connections, refer to the Bluemix panel for the DB2 Warehouse service.
<Fig here>  
- Test the connection.
- Load the metadata for the schema you want to use for this usecase.
<Fig here>

### Create a data module by connecting to DB2 Warehouse on Cloud
- Select "My Content" option form the menu on left side. Create folder/subfolders **MortgageAssets**. 
- Select "New" > "Data Servers" > "DB2WarehouseDataServerConnection"  > "Your Schema" and click on "Start" 
- Select the "Your Schema" > "Table name" (E.g. Mortgage Report New) and drag to the "New Data Module" panel.
- Select "Save" from the top left menu to save the data module. Save the data module in the folder create in "My Content" above.
