# Index
- [x] Current Project Background
  - [x] Astrus IDD (Integrity Due Dilegence) Product
  - [x] Watson Data Explorer, IBM Product
  - [x] Risk Segments
  - [x] Report generation process 
- [x] New Analytics Project
  - [x] Info
  - [x] Objectives
  - [x] Assumptions     
- [x] Proposed Technologies
- [x] High Level Architecture

# Current Project Background
### Astrus IDD (Integrity Due Dilegence) Product
- KPMG currently uses Astrus IDD product to do 3rd party background check on various companies for a client.
- Client sends a request to KPMG to run IDD process
- KPMG gets 10000 IDD requests/month
```
Client ------runs-----(IDD process) 1----*  Company 1
                                            Company 2
                                            ...
                                            Company n   

```

### Watson Data Explorer, IBM Product 
KPMG uses a product from IBM known as Watson Data Explorer (based on Watson) to do NLP 
```
Foe each company,
DATA EXPLORER -----retrieves----> APPROX 300 ARTICLES 
                                  -----fech details-----> 2000/3000 DOCUMENTS 
                                  -----stores in-----> DB2
                                  -----triggers-----> RISK ANALYTICS(6 SEGMENTS)
                                  

```
### Risk Segments
1. Law Suits
2. Adverse Press on companies
3. Background details (E.g. Company details, Stock price performance etc)
4. Key Shareholders details,owns > 5% ownership in companies (E.g. Background checks)
5. Shareholders (E.g. Check for Adverse Press) 
6. ? 

### Report generation process
- Watson results are analyzed by KPMG Analysts
- 20% results are in different languages
- Generates reports using EDD(Enhanced Due Diligence) process
- Old SLA
  - 72 hours to Analyze Watson Results
  - 3 days for review of response/reports
- 600-700 reports/month
- Enhancements
  - Provided Analysts full text search capabilities using SOLR 
  - Implemented language translation using *SysTran Product*
  - Automate report generation using *Inhouse product* 
  - Exiger, Due Diligence Players acquired DDIQ(Due Diligence IQ), has 15-20 min SLA for Entity lookup
  
# New Analytics Project
### Info
1. KPMG wants to enable clients to do a pre check on the various entities(Companies) and generate a *Red Flag Report*
2. SLA to complete the whole process is 10 minutes from the point the entity
3. Red Flag Report will be generated based on 6 Risk Segments
  - Law Suits 
  - Sanctions
  - Background check
  - Litigations
  - ?
  - ?
 
 ### Objectives
 1. Powerful Analytics
    Handled by Anaytics team from Xoriant
 2. Data Sourcing
    - This will be taken care by startup Import.io
    - Data needs to be sourced from approximatel 40 sources
    - 40 sources divided into static and dynamic websites (e.g. Search based websites). Currently we have only 2-3 sources.
    - Import.io has to write close to 300 different *Extractors* to extract data for an entity. 
 3. Infrastructure
    - Build a powerful infrastructure to handle the request from the point of Entity search based on various extractors to triggering Analytics platform to compute the Risk Score for generating Red Flag Report.
    - Insfrastructure should be totally elastic as the workloads are not consistent. The chosen architecture should be able to scale up/down for *compute* and *storage* independanlty and based on usage pattern. 
 
### Assumptions
#### Total requests/month
 KPMG is expecting 10,000 entity search requests/month.
 
#### Total input sources to search entity information
 KPMG has identified 300 sources, hence Import.io will have to provide 300 Extractors. 
 
#### Total requests to be supported
 Based on above, we need to support close to 3 Million requests/month

#### KPMG's Assumption on existing requests from clients
- Based on KPMG current observations, we will running only 50 sources, so we will have to execute 50 extractors at any one point in time for each entity.
- Based on 4 we should be able to support 500,000 requests/month. 
 
#### Storage requirements
- Per extractors, we get approximately 10 documents in resultset.
- We should be able to support *~ 50,000*10= 5Million docs/month* in short term and * ~3 Million*10 = 30Mil docs/month*.
- What is the size of documents ?
- How long do we store the documents, per request/day/month etc ?

#### Analytics Capabilities
- Analytics will be triggered once extractor process is completed.
- 6 different Analytics jobs will be run based on the 6 risk segments.
- Analytics will be run on a filtered set of 50 Million documents.

# Proposed Technologies
 
 
 
 
  
  
 
