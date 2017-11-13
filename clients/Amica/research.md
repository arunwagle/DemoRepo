
<img src="https://github.com/arunwagle/DemoRepo/blob/master/clients/Amica/images/DB2%20Offerings.png">

# Db2 Warehouse on Cloud: A Fully Managed Analytics Warehouse
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


### Sizing calculator
http://dashdb-configurator.stage1.mybluemix.net
```
Note:
Db2 Warehouse on Cloud – MPP Large Plan
There is actually an MPP Large size that is available – referred to as “super node” internally (and this is for SoftLayer only).
This size hasn’t been officially announced, nor mentioned in the Bluemix catalog but it is available for order if customers require very large (e.g. 100TB to PB sized) environments

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

# DB2 Warehouse on Cloud details
https://w3-connections.ibm.com/wikis/home?lang=en#!/wiki/Wf58c4c538dbf_45b4_b7a7_5003d0ceb79b/page/Db2%20Warehouse%20on%20Cloud

# Questions
1. Requirements for backup and recovery strategy 
2. Requirements for High availability (HA)
3. Requirements for Disaster recovery (DR) 


