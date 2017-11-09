# Excel to DB mapping - Internal use 


1. Est. NAV in Base CCY *: Cell G10
VLOOKUP(VLOOKUP(G7,MAPPING!$A:$B,2,FALSE),'Fund NAV'!$A:$C,3,FALSE)+G2+G1+SUMIF('ALADDIN-SUB-RED'!$A:$A,Assets!G8,'ALADDIN-SUB-RED'!$E:$E)


a.    VLOOKUP(G7,MAPPING!$A:$B,2,FALSE)
      = VLOOKUP('Crystal Japan Fund', MAPPING(Sheet)- range col A: col B, return col 2 value, exact match)
      = returns I-CJF

b.    VLOOKUP(VLOOKUP(G7,MAPPING!$A:$B,2,FALSE),'Fund NAV'!$A:$C,3,FALSE)
          = VLOOKUP(Step 1 result(I-CJF), Fund NAV(Sheet)- range col A: col C, return col 3 value, exact match)
          = returns C48 (56683885.37)
          ### Query: Select NAV_BASE_CCY from FUND_NAV_DAILY_PL where FUND_ID='I-CJF'


2. Est. NAV in USD : Cell G9 = Val of G10      [Discuss this]
                  Cell D9 = Val of G9

3. CUSTODIAN TOTAL CASH: C18:D18:G18
   a. USD: C19:D19:G19
            i. G19 = G21+G23+G25+G30
                  G21(BNY Liquidity (USD)), G25 (BBH (USD)), G30(Equity PB (USD)) = not used
                  G23 = BBH (USD)
                      =SUMIF('BBH - Cash'!D:D,"CRYSTAL JAPAN FUND",'BBH - Cash'!A:A)
                      = sum of all the 'Actual Available Balance' where Currency Account Name = 'CRYSTAL JAPAN FUND'
                  ### Query:  Select sum(ACT_AVAIL_BAL) from BBH_CASH where FUND_ID='I-CJF' ;

   b. JPY: C20:D20:G20
        i. G19 = =G22+G24+G26+G31
           G22, G26, G31 = not used
           G24 = BBH (JPY)
               =SUMIF('BBH - Cash'!D:D,"JPY CRYSTAL JAPAN FUND",'BBH - Cash'!A:A)
               = sum of all the 'Actual Available Balance' where Currency Account Name = 'JPY CRYSTAL JAPAN FUND'
           ### Query: Select sum(ACT_AVAIL_BAL) from BBH_CASH where FUND_ID='I-CJF' ;


4. CUSTODIAN TOTAL SECURITIES: C32:D32:G32
      a. USD: C33:D33:G33
               i. G33 = G37+G39+G41+G43
                     G37 G41 G43 G39 = not used

      b. USD: C34:D34:G34
              i. G34 = G38+G40+G42+G45
                    G38 G42 G45 = not used
                    G40 = BBH (JPY)
                    =SUMIF('BBH - Custody'!B:B,"Crystal Japan Fund",'BBH - Custody'!Y:Y)
                    = sum of all the 'Local Market Value' where Account Name = 'CRYSTAL JAPAN FUND'
                ### Query: Select sum(ACT_AVAIL_BAL) from BBH_CASH where FUND_ID='I-CJF' ;

5. ALADDIN TOTAL SECURITIES: C79:D79:G79
      a. USD: C80:D80:G80

      b. JPY: C81:D81:G81
      G81: =SUMIF('ALADDIN -SEC'!$W:$W,Assets!G$8&$C$81,'ALADDIN -SEC'!$K:$K)   //SUMIF( range, criteria, [sum_range] )
            // get Notational Market Value for I-CJF & JPY
            ### Query: Select NOTIONAL_MKT_VAL,CURRENCY from ALADDIN_SEC where FUND_ID='I-CJF' and CURRENCY='JPY'

6. ALADDIN TOTAL CASH:C72:D72:G72
      a. ALADDIN USD:C73:D73:G73
        G73: = IF(ISNA(VLOOKUP("USD CASH(Alpha Committed)",'I-CJF'!$A:$D,4,FALSE)),0,VLOOKUP("USD CASH(Alpha Committed)",'I-CJF'!$A:$D,4,FALSE))

              i  VLOOKUP("USD CASH(Alpha Committed)",'I-CJF'!$A:$D,4,FALSE)
                = VLOOKUP(USD CASH(Alpha Committed), I-CJF(Sheet)- range col A: col D, return col 4 value, exact match)

              ii IF(ISNA(i) is TRUE then return 0 else return value computed in i )

      b. ALADDIN JPY:C74:D74:G74
         G74: = IF(ISNA(VLOOKUP("JPY CASH(Alpha Committed)",'I-CJF'!$A:$D,4,FALSE)),0,VLOOKUP("JPY CASH(Alpha Committed)",'I-CJF'!$A:$D,4,FALSE))

            i  VLOOKUP("JPY CASH(Alpha Committed)",'I-CJF'!$A:$D,4,FALSE)
              = VLOOKUP(JPY CASH(Alpha Committed), I-CJF(Sheet)- range col A: col D, return col 4 value, exact match)

            ii IF(ISNA(i) is TRUE then return 0 else return value computed in i )
      c. G72 = G73 + G74/D5(Exchange rate JPY to USD)


7. ALADDIN TOTAL ASSETS: C67:D67:G67
      G67=G79+G72+G87

8. SOCGEN TOTAL EQUITY:C56:D56:G56 [TODO]
    a. G56 =VLOOKUP("ABBB7"&$D$3&89855,'FCM-NE'!AI:AM,2,FALSE)/D5
            = VLOOKUP("ABBB7"&<???>&89855, FCM-NE(Sheet)- range col AI: col AM, return col 2 value, exact match)/D5(Exchange rate JPY to USD)

            Note:
            Search term = ABBB7(BALANCETYPE[A] + SortLevel[BBB] + Office[7]) + 42947(DateInt) + 89855 (Account)
            Return Value = NETLIQ/D5(Exchange rate JPY to USD)
            ### Query: Select NET_LIQ from FCM_NE_BALANCE_EQUITY_BY_CURRENCY where FUND_ID='I-CJF' and AS_OF_DATE='' and BAL_TYPE='A' AND SORT_LEVEL='BBB' AND ACCT_NUM='89855'

    b. G57  = (VLOOKUP("ABBB7"&$D$3&89855,'FCM-NE'!AI:AM,3,FALSE)+VLOOKUP("ABBB7"&$D$3&89855,'FCM-NE'!AI:AM,5,FALSE))/D5
            = VLOOKUP("ABBB7"&<???>&89855, FCM-NE(Sheet)- range col AI: col AM, return col 3 value, exact match) +
              VLOOKUP("ABBB7"&<???>&89855, FCM-NE(Sheet)- range col AI: col AM, return col 5 value, exact match)
              /D5(Exchange rate JPY to USD)

              Note:
              Search term = ABBB7(BALANCETYPE[A] + SortLevel[BBB] + Office[7]) + 42947(DateInt) + 89855 (Account)
              Return Value = FUTINITMARGIN + (NETLIQ - TOTALEQUITY)/D5(Exchange rate JPY to USD)
              ### Query: Select NET_LIQ, FUTINITMARGIN, TOTALEQUITY from FCM_NE_BALANCE_EQUITY_BY_CURRENCY where FUND_ID='I-CJF' and AS_OF_DATE='' and BAL_TYPE='A' AND SORT_LEVEL='BBB' AND ACCT_NUM='89855'



#
