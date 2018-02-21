# What we know so far
### Astrus IDD (Integrity Due Dilegence) Product
KPMG currently uses Astrus IDD product to do 3rd party background check on various companies for a client.
Client sends a request to KPMG to run IDD process
```
Client ------runs-----(IDD process) 1----*  Company 1
                                            Company 2
                                            ...
                                            Company n   

```

### Data Explorer, IBM Product 
KPMG uses a product from IBM known as Data Explorer (based on Watson) to do NLP 
```
Foe each company,
DATA EXPLORER -----retrieves----> APPROX 300 ARTICLES 
                                  ---fech details---> 2000/3000 DOCUMENTS 
                                  ---stores in---> DB2
                                  -----triggers----> RISK ANALYTICS(6 SEGMENTS)
                                  

```
### Analytics Segments
1. Law Suits
2. Adverse Press
3. Background details (E.g. Company details, Stock price performance etc)
4. Key Shareholders details,owns > 5% ownership in companies (E.g. Background checks)
5. Shareholders (E.g. Check for Adverse Press) 
6. ? 
