
<img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Amica/images/DB2%20Offerings.png">

# Db2 Warehouse on Cloud: A Fully Managed Analytics Warehouse
### Current version 
v2.1

### IBM Responsibility
- OS and database software installation
- Optimized configuration for analytics workloads
- BLU Acceleration "load and go" simplicity
  - No need for creating auxiliary structures like indexes or aggregates
  - Automatic memory management
  - Automatic statistics gathering
  - Automatic space reclamation
  - Pre-configured workload management
- Ongoing OS and database software maintenance 
- Automated daily backups
- 24/7 monitoring and restart after hardware or software failure
- Ongoing risk assessment and security monitoring
- Upgrade support moving to a larger size

### Client Responsibility
- Schema definition
- Data loading
- User management and database access control
- Application, ETL connectivity


### Sizing
Recommendations based on below assumtions
- 1.5 TB of compressed data (provided by client)
- Compression ratio of 3X
- % of Frequently accessed rows 30%
- % of Frequently accessed columns 50%

Recommended configuration based on sizing calculator- 
- DB2 Warehouse on Cloud Enterprise MPP supernode
- Cores: 48 cores per node
- Storage per node: 4.4 TB
- Total nodes: 3
- Total cores: 144
- Total Memory: 3TB
- Total Storage: 13.2 TB

##### Sizing calculator
http://dashdb-configurator.stage1.mybluemix.net
```
Note:
Db2 Warehouse on Cloud – MPP Large Plan
There is actually an MPP Large size that is available – referred to as “super node” internally (and this is for SoftLayer only).

Specifications (per node)
48 cores
1 TB RAM
4.4 TB of physical storage for user data (~ 13 TB of uncompressed user data assuming typical compression)
3.6 TB of physical storage for temporary data (~ 11 TB of uncompressed temporary data assuming typical compression)
Jumpstart & Accelerator programs available

```

# Deployment options : Bluemix Public vs. Bluemix Dedicated

- Public or Dedicated, Db2 Warehouse on Cloud is deployed on dedicated servers
- Bluemix Dedicated, Db2 Warehouse on Cloud is included in the private network for that environment
- Bluemix Dedicated is not required for private networking. Private networking for CDS services is available with the **IBM Cloud Integrated Analytics Environment (ICIAE)**
- Bluemix Dedicated required only if the plan is to expand to use other data services. 


# Data centers: CDS Service Availability Matrix
https://w3-connections.ibm.com/wikis/home?lang=en-us#!/wiki/W8d93a574563a_4a54_8670_27e66e3f2799/page/CDS%20Service%20Availability%20Matrix

# Data Migration using Lift
- With Bluemix Lift you can migrate your data from IBM PureData System for Analytics and IBM Db2 to the IBM Db2 Warehouse on Cloud data warehouse and IBM Db2 Hosted respectively. Additionally, CSV flat files can be used to load IBM Db2 Warehouse on Cloud and IBM Db2 Hosted
- Achieve data ingest speeds tens of times faster than traditional data movement solutions.
- Eliminate the downtime associated with database migrations.
- Bluemix Lift encrypts your data as it travels across the wire.
- Kick off a large database migration and walk away without worry.

# Details on MicroStrategy
- Latest Supported Version - **IBM DB2 9.7 and higher**
- Current driver version for Linux, Windows, PowerLinux & Mac provided by IBM for DB1 Warehouse on Cloud- **v11.1**
- Driver support by Microstrategy: **IBM DB2 11.1**, IBM DB2 10.5, IBM DB2 10.0, IBM DB2 9.7
- Refer to Microstrategy Datasheet https://github.com/arunwagle/DemoRepo/blob/master/clients/Amica/images/Data-Connectivity-Product-Sheet_IBM-DB2.pdf
- Questions
  - What is the highest version of Microstrategy which is supported by Db2 9.7?
    
    Ans: Microstategy connects to DB2 using JDBC drivers, Current version of Microstrategy supports **IBM DB2 9.7 and higher**& above. Also the current DB2Warehouse on Cloud supports **IBM DB2 11.1**, IBM DB2 10.5, IBM DB2 10.0, IBM DB2 9.7. Unless we are looking for specific version for MicroStrategy we should be good.
  - Also, what versions of Microstrategy are supported by Db2WH on Cloud?
    
    Ans: Current Version for MicroStrategy is supported for sure. Refer to Data Sheet above. If any specific versions needs to be supported, let us know the details

# Data backups
- Db2 Warehouse on Cloud, the last 2 daily backups are retained
- These backups are used exclusively by IBM for only system recovery purposes in the event of a disaster or system loss
- Data can be exported using Db2 tools such as IBM Data Studio or by using the db2 export command and then populate othe environments (DEV/QA)

# HA & DR
- (HA) is provided by IBM restarting software, restarting downed servers, and replacing failing servers
- Disaster recovery (DR) is accomplished through a dual ETL approach where the customer does the same insert/update/delete/load activity to two separate instances
- Not customizable
- More advanced DR ad HA will be available in future, no dates yet.

# Security
- Encrypted data at-rest using AES 256
- Encrypted data in-motion - via SSL/TLS
- Application authentication using embedded LDAP server
- Authorization – Grant permissions to specific tables, rows, roles
- Optionally restrict access to specify client host names
- Host firewall to protect from port scans/network intrusion
- Private VLAN and VPN options available with ICIAE network service
- ISO 27001 certified
- SOC 2 Type 1 & SOC 2 Type 2 certified, SOC 3
- HIPAA-ready
- Privacy Shield certified
- Monitored 24x7
- Fully managed for setup, configuration, tuning and DR operations
- InfoSphere Guardium-based audit reports and monitoring
- Sensitive data monitoring through Guardium Database Activity monitoring to discover sensitive data, connections and SQL statements


# Links
- DB2 Warehouse on Cloud details https://w3-connections.ibm.com/wikis/home?lang=en#!/wiki/Wf58c4c538dbf_45b4_b7a7_5003d0ceb79b/page/Db2%20Warehouse%20on%20Cloud
- FAQ https://www.ibm.com/support/knowledgecenter/en/SS6NHC/com.ibm.swg.im.dashdb.doc/managed_service.html
- Security and Compliance https://www.ibm.com/support/knowledgecenter/SS6NHC/com.ibm.swg.im.dashdb.security.doc/doc/compliances.html

# Questions
1. Requirements for backup and recovery strategy ?
2. Requirements for High availability (HA) ?
3. Requirements for Disaster recovery (DR) ?
4. What product and version of MicroStrategy is being used ? 
5. Why do they think need to increase this to internet pipe to 800 MBps ? Are there any specific data transfer requirement ? 


