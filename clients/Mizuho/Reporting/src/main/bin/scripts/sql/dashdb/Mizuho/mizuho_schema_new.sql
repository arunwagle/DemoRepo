CREATE TABLE  REF_FUND
(
     ID                               VARCHAR(50) NOT NULL PRIMARY KEY,
     DESCRIPTION                      VARCHAR(50)
);

CREATE TABLE  REF_FUND_MAPPING
(
    ID                              INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1, NO CACHE ),
    FUND_ID                         VARCHAR(50) NOT NULL,
    VALUE                           VARCHAR(100),
    SYSTEM                          VARCHAR(50),
    BASE_CURR                       VARCHAR(100),
    DESCRIPTION                     VARCHAR(1024),
    MODIFIED_DATE                   VARCHAR(10),
    FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED
);



-- ENTER SQL STATEMENTS BELOW OR LOAD A SQL SCRIPT INTO THE EDITOR FROM THE TOOLBAR.
CREATE TABLE  BBH_CUSTODY
(
     ACCT_NUM                         VARCHAR(50) NOT NULL ,
     FUND_NAME                        VARCHAR(100) NOT NULL,
     FUND_ID                          VARCHAR(50) NOT NULL ,--  MAPS TO REF_FUND_MAPPING ID COLUMN
     CUSTODY_SEC_ID                   VARCHAR(50),
     SEDOL                            VARCHAR(50),
     CUSIP                            VARCHAR(50),
     ISIN                             VARCHAR(50),
     SEC_DESC                         VARCHAR(100),
     CAP_DESC                         VARCHAR(100),
     MATURITY_DATE                    VARCHAR(50),
     LOC                              VARCHAR(10),
     LOC_ACCT_NAME                    VARCHAR(10),
     REG_DESC                         VARCHAR(100),
     PAYDOWN_FACTOR                   VARCHAR(50),
     CURR_FACE_VAL                    VARCHAR(50),
     CUSTODY_POS                      VARCHAR(50),
     TOT_AVAIL_POS                    VARCHAR(50),
     POS_DATE                         VARCHAR(50),
     PRICE_DATE                       VARCHAR(50),
     PRICE                            VARCHAR(50),
     PRICING_CURR                     VARCHAR(10),
     LOCAL_PRICE                      VARCHAR(50),
     LOCAL_CURR                       VARCHAR(10),
     FX_RATE                          VARCHAR(50),
     MARKET_VAL                       VARCHAR(50),
     LOCAL_MARKET_VAL                 DECIMAL(20,10),
     AS_OF_DATE                       VARCHAR(50) NOT NULL,
     MODIFIED_DATE                    VARCHAR(50) NOT NULL,
     FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED,
     UNIQUE (ACCT_NUM,FUND_ID,AS_OF_DATE)
);


-- ENTER SQL STATEMENTS BELOW OR LOAD A SQL SCRIPT INTO THE EDITOR FROM THE TOOLBAR.
CREATE TABLE  BBH_CASH
(
     ACCT_NUM                         VARCHAR(50) NOT NULL  ,  -- MAPS TO HEAD ACCOUNT NUMBER IN EXCEL FILE
     FUND_NAME                        VARCHAR(100) NOT NULL, -- MAPS TO CURRENCY ACCOUNT NAME IN EXCEL FILE
     FUND_ID                          VARCHAR(50) NOT NULL ,--  MAPS TO REF_FUND_MAPPING ID COLUMN
     ACT_AVAIL_BAL                    DECIMAL(20,10),
     ACT_VAR_AMT                      VARCHAR(50),
     DEPOSIT_BANK                     VARCHAR(100) NOT NULL, -- CURRENCY ACCOUNT NAME
     CURR_CODE                        VARCHAR(10),
     OPEN_AVAIL_CMS_SWEEP_RETURN      VARCHAR(50),
     OPEN_AVAIL_BAL                   VARCHAR(50),
     PRIOR_DAY_NAV                    VARCHAR(50),
     PROJ_CLOSE_AVAIL_BAL             VARCHAR(50),
     SUB_ACCT_NUM                     VARCHAR(50) NOT NULL ,
     AS_OF_DATE                       VARCHAR(10) NOT NULL, -- MAPS TO VALUE DATE IN EXCEL
     MODIFIED_DATE                    VARCHAR(50) NOT NULL,
     FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED
    --  UNIQUE (ACCT_NUM,FUND_ID,AS_OF_DATE)
);



CREATE TABLE  ALADDIN_VARMAR
(
     FUND_ID                          VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
     CUSIP                            VARCHAR(50) NOT NULL,
     SEC_DESC                         VARCHAR(1024),
     CURRENCY                         VARCHAR(10),
     CURRENT_FACE                     VARCHAR(50),
     SETTLED                          VARCHAR(50),
     UNSETTLED                        VARCHAR(50),
     FX_RATE                          VARCHAR(50),
     AS_OF_DATE                       VARCHAR(10) NOT NULL,
     MODIFIED_DATE                    VARCHAR(50) NOT NULL,
     FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED
    --  UNIQUE (FUND_ID,CUSIP,AS_OF_DATE)
) DISTRIBUTE BY HASH(FUND_ID);



CREATE TABLE  ALADDIN_SEC
(
     FUND_ID                          VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
     CUSIP                            VARCHAR(50) NOT NULL,
     CURRENCY                         VARCHAR(10),
     SEC_TYPE                         VARCHAR(50),
     TICKER_COUPON_MATURITY           VARCHAR(100),
     SEC_DESC                         VARCHAR(1024),
     ISIN                             VARCHAR(50),
     ORIG_FACE                        VARCHAR(50),
     SETTLED                          VARCHAR(50),
     NOTIONAL_MKT_VAL                 DECIMAL(20,10),
     BASE_CURR_MKT_VAL_ACC_INT        VARCHAR(50),
     BASE_CURR_MKT_INT                VARCHAR(50),
     MATURITY_DATE                    VARCHAR(50),
     ISSUE_DATE                       VARCHAR(50),
     BASE_CURR_FX_RATE                VARCHAR(50),
     MKT_PRICE                        VARCHAR(50),
     COUPON                           VARCHAR(10),
     SNP_RATING                       VARCHAR(10),
     AS_OF_DATE                       VARCHAR(10) NOT NULL,
     MODIFIED_DATE                    VARCHAR(50) NOT NULL,
     FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED,
     UNIQUE (FUND_ID,CUSIP,AS_OF_DATE)
);


CREATE TABLE  ALADDIN_FUT_POS
(
     FUND_ID                          VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
     REUTER                           VARCHAR(50) NOT NULL,
     CUSIP                            VARCHAR(50) NOT NULL,
     SEC_DESC                         VARCHAR(1024),
     ORIG_FACE                        VARCHAR(50),
     CURR_FACE                        VARCHAR(50),
     CURRENCY                         VARCHAR(10),
     UNSETTLED                        VARCHAR(50),
     MKT_PRICE                        VARCHAR(50),
     COUNTER_PRTY_TIC                 VARCHAR(50),
     AS_OF_DATE                       VARCHAR(50) NOT NULL,
     MODIFIED_DATE                    VARCHAR(50) NOT NULL,
     FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED,
     UNIQUE (FUND_ID,CUSIP,AS_OF_DATE)
);


CREATE TABLE  FCM_NE_BALANCE_EQUITY_BY_CURRENCY
(
    BAL_TYPE                          VARCHAR(10),
    SORT_LEVEL                        VARCHAR(50),
    COMPANY                           VARCHAR(50),
    FIRM                              VARCHAR(10),
    OFFICE                            VARCHAR(10),
    ACCT_NUM                          VARCHAR(50) NOT NULL ,  -- MAPS TO HEAD ACCOUNT NUMBER IN EXCEL FILE
    SALESMAN                          VARCHAR(50),
    AS_OF_DATE                        VARCHAR(50) NULL,  -- Maps to LBDAY
    FUND_NAME                         VARCHAR(100) NOT NULL, -- MAPS TO ACCOUNTNAME NAME IN EXCEL FILE
    FUND_ID                           VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
    GROUP_ACCT_NUM                    VARCHAR(50),  -- MAPS TO  GROUPACCTNUM IN EXCEL FILE
    GROUP_FUND_NAME                   VARCHAR(50),  -- MAPS TO  GROUPACCTNAM IN EXCEL FILE
    ACCT_TYPE                         VARCHAR(10),
    CURRENCY                          VARCHAR(10),-- MAPS TO CURR IN EXCEL FILE
    BALANCE                           VARCHAR(50),
    FUT_INIT_MARGIN                   DECIMAL(20,10),
    FUT_MAINT_MARGIN                  VARCHAR(50),
    SEC_LONG_MKVAL                    VARCHAR(50),
    SEC_SHORT_MKVAL                   VARCHAR(50),
    OPT_LONG_MKVAL                    VARCHAR(50),
    OPT_SHORT_MKVAL                   VARCHAR(50),
    OPT_LONG_OTE                      VARCHAR(50),
    OPT_SHORT_OTE                     VARCHAR(50),
    NET_LIQ                           DECIMAL(20,10),
    MARGIN_EXCESS                     VARCHAR(50),
    MARGIN_COL_VAL                    VARCHAR(50),
    FUT_OTE                           VARCHAR(50),
    TOTAL_EQUITY                      DECIMAL(20,10),
    WITHDRAWABLE                      VARCHAR(50),
    TOT_CALLS                         VARCHAR(50),
    ACCT_CURR                         VARCHAR(10),
    MAST_CURR                         VARCHAR(10),
    CONV_ACCT                         VARCHAR(50),
    CONV_MAST                         VARCHAR(50),
    RATE_FAILS                        VARCHAR(10),
    MODIFIED_DATE                    VARCHAR(50) NOT NULL,
    FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED
    -- UNIQUE (FUND_ID,ACCT_NUM,AS_OF_DATE), what is the unique key in thsi table
);


CREATE TABLE  FCM_MS_BALANCE_SUMMARY
(
    ACCT_NUM_1                        VARCHAR(50) NOT NULL ,  -- MAPS TO 0 IN EXCEL FILE
    ACCT_NUM                          VARCHAR(50) NOT NULL ,  -- MAPS TO SecuredAccount IN EXCEL FILE
    FUND_NAME                         VARCHAR(100) NOT NULL, -- MAPS TO AccountName NAME IN EXCEL FILE
    FUND_ID                           VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
    AS_OF_DATE                        VARCHAR(50) NOT NULL,  -- Maps to StatementDate
    CURRENCY                          VARCHAR(10),-- MAPS TO CURR IN EXCEL FILE
    SEG_IND                           VARCHAR(10), --maps to SegregatedInd
    COMB_IND                          VARCHAR(10), --maps to CombinedInd
    CONV_IND                          VARCHAR(10),-- maps to ConvertedInd
    FX_RATE                           VARCHAR(50),
    FX_MULTIPLIER_IND                 VARCHAR(10), -- FxMultiplierInd
    FX_BASE_CURR                      VARCHAR(10),   -- maps to FXBaseCurrency
    OPEN_BAL                          VARCHAR(50),-- maps to OpeningBalance
    CASH_ACTVY                        VARCHAR(50),-- maps to CashActivity
    FUT_COMM                          VARCHAR(50), -- FuturesCommission
    FUT_FEES                          VARCHAR(50), -- FuturesFees
    GROSS_PL                          VARCHAR(50), -- GrossPL
    NET_PL                            VARCHAR(50), -- NetPL
    CLOSE_BAL                         VARCHAR(50),-- ClosingBalance
    OPEN_TRADE_EQUITY                 VARCHAR(50),-- OpenTradeEquity
    PENDING_PS                        VARCHAR(50),-- PendingPS
    TOTAL_EQUITY                      VARCHAR(50),
    LME_DSCNT_MARGIN                  VARCHAR(50), -- maps to LMEDiscountMargin
    INIT_MARGIN                       VARCHAR(50), -- InitialMargin
    NON_CASH_COLLATERAL               VARCHAR(50), -- NonCashCollateral
    EQUITY_SUR_DEFICIT                VARCHAR(50), -- EquitySurplusDeficit
    PEND_PREMIUM                      VARCHAR(50), -- PendingPremium
    FORECAST_EQUITY                   VARCHAR(50), -- ForecastEquity
    NET_LIQ_VAL                       VARCHAR(50), -- NetLiquidatingValue
    MTD_NET_REALZ_OPT_PROCEEDS        VARCHAR(50), -- MTDNetRealizedOptionsProceeds
    MTD_NET_REALZ_FUT_PL              VARCHAR(50), -- MTDNetRealizedFuturePL
    PROJ_SETTLE_AMT                   VARCHAR(50), -- ProjectedSettlementAmt
    PROJ_VAL_DATE                     VARCHAR(50),  -- Maps to ProjectedValueDate
    PEND_NONCASH_AMT                  VARCHAR(50), -- PendingNonCashAmt
    CASH_NONCASH_AMT                  VARCHAR(50), -- CashNonCashAmt
    COLLATERAL_SUR_DEFICIT            VARCHAR(50), -- CollateralSurplusDeficit
    CASH_COLLATERAL_AMT               VARCHAR(50), -- CashCollateralAmt
    REALIZE_VM                        VARCHAR(50), -- RealizedVM
    VM_ADJUST                         VARCHAR(50), -- VMAdjustments
    TOT_NET_PL                        VARCHAR(50), -- TotalNetPL
    PEND_CASH                         VARCHAR(50), -- PendingCash
    PEND_CASH_VAL_DATE                VARCHAR(50),  -- Maps to PendingCashValueDate
    EXCESS_MARGIN_PCT                 VARCHAR(50),  -- Maps to ExcessMarginPercentage
    MTD_MTM_AMT                       VARCHAR(50), -- MTDMTMAmt
    MODIFIED_DATE                    VARCHAR(50) NOT NULL,
    FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED
    -- UNIQUE (FUND_ID,ACCT_NUM,AS_OF_DATE), what is the unique key in thsi table
);




CREATE TABLE  FUND_NAV_DAILY_PL
(
    FUND_ID                           VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
    AS_OF_DATE                        VARCHAR(50) NOT NULL,  -- Maps to StatementDate
    BASE_CURR                         VARCHAR(10),-- MAPS TO Base CCY IN EXCEL FILE
    NAV_BASE_CCY                      DECIMAL(20,10),  -- maps to NAV (Base CCY)
    MODIFIED_DATE                    VARCHAR(50) NOT NULL,
    FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED,
    UNIQUE (FUND_ID,AS_OF_DATE)

);



CREATE TABLE  FUND_DAILY_PL
(
    INVESTMENT_HLDGS VARCHAR(50) ,
    BB_TICK VARCHAR(50) ,
    STATED_MATURITY VARCHAR(50) ,
    POS_AMT DECIMAL(20,10),
    BASE_MKT_VAL VARCHAR(50) ,
    LOCAL_MKT_VAL VARCHAR(50) ,
    LOCAL_NOT_MKT_VAL VARCHAR(50) ,
    FX_RATE VARCHAR(50) ,
    BASE_NOT_MKT_VAL VARCHAR(50) ,
    PERCENT_NAV VARCHAR(50) ,
    NOT_PERCENT_OF_NAV VARCHAR(50) ,
    NOT_PERCENT_OF_LONG VARCHAR(50) ,
    NOT_PERCENT_OF_SHORT VARCHAR(50) ,
    GROSS_NOT_VAL VARCHAR(50) ,
    PERCENT_GROSS_NOT_DIVIDE_BY_NAV VARCHAR(50) ,
    NOT_LONG VARCHAR(50) ,
    NOT_SHORT VARCHAR(50) ,
    CUSIP VARCHAR(50) ,
    CURRENCY VARCHAR(50) ,
    LAST_CLOSE VARCHAR(50) ,
    CONTRACT_SIZE VARCHAR(50) ,
    RIC_PREFIX VARCHAR(50) ,
    TICK_VALUE VARCHAR(50) ,
    AS_OF_DATE VARCHAR(50) ,
    RISK_DATE VARCHAR(50) ,
    FUND_ID VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
    MODIFIED_DATE                    VARCHAR(50) NOT NULL,
    FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED
    -- UNIQUE (FUND_ID,AS_OF_DATE)

);

CREATE TABLE  MAI_HOLDINGS_DAILY
(
    ID                              INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1, NO CACHE ),
    FUND_ID                         VARCHAR(50) NOT NULL,
    AS_OF_DATE                      VARCHAR(50) ,
    CURRENCY                        VARCHAR(50) ,
    FUND_PARENT                     VARCHAR(50) ,
    FUND_CHILD                      VARCHAR(50) ,
    VALUE                           VARCHAR(100),
    FORMAT                          VARCHAR(10),
    MODIFIED_DATE                   VARCHAR(10),
    FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED
);

----
Insert STATEMENTS
Insert into REF_FUND_MAPPING(FUND_ID, VALUE, MODIFIED_DATE) values('I-CJF', 'JPY CRYSTAL JAPAN FUND','2017-10-13')



-- Enter SQL statements below or load a SQL script into the editor from the toolbar.


Insert into MAI_HOLDINGS_DAILY (FUND_ID, AS_OF_DATE, CURRENCY, FUND_PARENT, FUND_CHILD, VALUE, FORMAT)
Select FUND_ID,AS_OF_DATE, BASE_CURR, 'Est. NAV in USD','EST. NAV IN BASE CCY *',NAV_BASE_CCY,'CURRENCY'  from FUND_NAV_DAILY_PL a, REF_FUND b where a.FUND_ID=b.id


Insert into MAI_HOLDINGS_DAILY (FUND_ID, AS_OF_DATE, CURRENCY, FUND_PARENT, FUND_CHILD, VALUE, FORMAT)
Select FUND_ID,AS_OF_DATE, CURRENCY, 'ALADDIN TOTAL SECURITIES',CURRENCY,NOTIONAL_MKT_VAL,'CURRENCY'  from ALADDIN_SEC a, REF_FUND b where a.FUND_ID=b.id
