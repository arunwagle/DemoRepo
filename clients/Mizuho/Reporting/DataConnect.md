# Perform the following tasks
- [x] Create table in DashDB using the SQL scripts
- [x] Create Source and Target Connections 
- [x] Create Data Flow Design, this will create an activity
- [x] Schedule the activity to run daily

### Create table in DashDB using the SQL scripts
- Launch DashDB console from Bluemix.
- Select "Run SQL" option form the menu
- Copy the SQL and run in the editor. 
  - Note: SQL files are located in $REPO_HOME/clients/Mizuho/Reporting/src/main/bin/scripts/sql
  
### Create Source and Target Connections 
- Launch Data Connect from Bluemix.
- Create "New Connection" to **Bluemix Object Storage**. This process is self explanatory. 
  - Note: Each service in Bluemix has a "Service Credentials" section. You will need information from that to create a connection.
- Create "New Connection" to **DashDB**. This process is self explanatory.   
  - Note: Each service in Bluemix has a "Service Credentials" section. You will need information from that to create a connection.
  
### Create Data Flow Design, this will create an activity
- You have launched Data Connect from Bluemix.
- Select "Design Flow" from the menu
- Add Source
  - While adding source you can select configure the data source. Some of the things you can do is change columns name, datatype etc.
  - Once you add the source you can also do certain cleanse operation, change schema, prepare data set etc
  - You can add multiple sources
- Add target
  - While adding target, select "Append to the table" and click on "Launch Mapping". This will map the source to the target columns

### Schedule the activity to run daily
- Run immediately OR
- Schedule to run at a particular interval.
  


  
