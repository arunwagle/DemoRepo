# Project Background
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
2. Adverse Press
3. Background details (E.g. Company details, Stock price performance etc)
4. Key Shareholders details,owns > 5% ownership in companies (E.g. Background checks)
5. Shareholders (E.g. Check for Adverse Press) 
6. ? 

### Report generation process
- Watson results are analyzed by KPMG Analysts. Results are in different languages
- Generates reports using EDD(Enhanced Due Diligence) process
- SLA
  - 72 hours to Analyze Watson Results
  - 3 days for review of response/reports
- 600-700 reports/month

  
