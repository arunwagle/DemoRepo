DROP TABLE REF_FUND;
CREATE TABLE  REF_FUND
(
     ID                               VARCHAR(50) NOT NULL PRIMARY KEY
);

DROP TABLE REF_FUND_MAPPING;
CREATE TABLE  REF_FUND_MAPPING
(
     ALADDIN_ID                       VARCHAR(50) NOT NULL,
     FUND_NAME                        VARCHAR(100),
     FUTURES_ACCT_ID                  VARCHAR(50),
     BTIG_ID                          VARCHAR(100),
     FUND_ID                          VARCHAR(100),
     NEWEDGE_ID                       VARCHAR(100),
     BASE                             VARCHAR(100),
     BARC_ID                          VARCHAR(100),
     FOREIGN KEY (ALADDIN_ID) REFERENCES REF_FUND(ID) NOT ENFORCED
);
-- DISTRIBUTE BY HASH( ID );


DROP TABLE BBH_CUSTODY;
-- ENTER SQL STATEMENTS BELOW OR LOAD A SQL SCRIPT INTO THE EDITOR FROM THE TOOLBAR.
CREATE TABLE  BBH_CUSTODY
(
     ACCT_NUM                         INTEGER NOT NULL ,
     FUND_NAME                        VARCHAR(100) NOT NULL,
     FUND_ID                          VARCHAR(50) NOT NULL ,--  MAPS TO REF_FUND_MAPPING ID COLUMN
     CUSTODY_SEC_ID                   INTEGER,
     SEDOL                            VARCHAR(50),
     CUSIP                            VARCHAR(50),
     ISIN                             VARCHAR(50),
     SEC_DESC                         VARCHAR(100),
     CAP_DESC                         VARCHAR(100),
     MATURITY_DATE                    DATE,
     LOC                              VARCHAR(10),
     LOC_ACCT_NAME                    VARCHAR(10),
     REG_DESC                         VARCHAR(100),
     PAYDOWN_FACTOR                   VARCHAR(50),
     CURR_FACE_VAL                    VARCHAR(50),
     CUSTODY_POS                      DECIMAL(20,4),
     TOT_AVAIL_POS                    DECIMAL(20,4),
     POS_DATE                         DATE,
     PRICE_DATE                       DATE,
     PRICE                            DECIMAL(20,10),
     PRICING_CURR                     VARCHAR(10),
     LOCAL_PRICE                      DECIMAL(20,10),
     LOCAL_CURR                       VARCHAR(10),
     FX_RATE                          DECIMAL(20,4),
     MARKET_VAL                       DECIMAL(20,10),
     LOCAL_MARKET_VAL                 DECIMAL(20,10),
     AS_OF_DATE                       DATE NOT NULL,
     FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED,
     UNIQUE (ACCT_NUM,FUND_ID,AS_OF_DATE)
);

DROP TABLE BBH_CASH;
-- ENTER SQL STATEMENTS BELOW OR LOAD A SQL SCRIPT INTO THE EDITOR FROM THE TOOLBAR.
CREATE TABLE  BBH_CASH
(
     ACCT_NUM                         INTEGER NOT NULL ,  -- MAPS TO HEAD ACCOUNT NUMBER IN EXCEL FILE
     FUND_NAME                        VARCHAR(100) NOT NULL, -- MAPS TO CURRENCY ACCOUNT NAME IN EXCEL FILE
     FUND_ID                          VARCHAR(50) NOT NULL ,--  MAPS TO REF_FUND_MAPPING ID COLUMN
     ACT_AVAIL_BAL                    DECIMAL(20,10),
     ACT_VAR_AMT                      DECIMAL(20,10),
     DEPOSIT_BANK                     VARCHAR(100) NOT NULL, -- CURRENCY ACCOUNT NAME
     CURR_CODE                        VARCHAR(10),
     OPEN_AVAIL_CMS_SWEEP_RETURN      DECIMAL(20,10),
     OPEN_AVAIL_BAL                   DECIMAL(20,10),
     PRIOR_DAY_NAV                    DECIMAL(20,10),
     PROJ_CLOSE_AVAIL_BAL             DECIMAL(20,10),
     SUB_ACCT_NUM                     INTEGER NOT NULL ,
     AS_OF_DATE                       DATE NOT NULL, -- MAPS TO VALUE DATE IN EXCEL
     FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED,
     UNIQUE (ACCT_NUM,FUND_ID,AS_OF_DATE)
);


DROP TABLE ALADDIN_VARMAR;
CREATE TABLE  ALADDIN_VARMAR
(
     FUND_ID                          VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
     CUSIP                            VARCHAR(50) NOT NULL,
     SEC_DESC                         VARCHAR(1024),
     CURRENCY                         VARCHAR(10),
     CURRENT_FACE                     DECIMAL(20,10),
     SETTLED                          DECIMAL(20,10),
     UNSETTLED                        DECIMAL(20,10),
     FX_RATE                          DECIMAL(20,10),
     AS_OF_DATE                       DATE NOT NULL,
     FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED,
     UNIQUE (FUND_ID,CUSIP,AS_OF_DATE)
);


DROP TABLE ALADDIN_SEC;
CREATE TABLE  ALADDIN_SEC
(
     FUND_ID                          VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
     CUSIP                            VARCHAR(50) NOT NULL,
     CURRENCY                         VARCHAR(10),
     SEC_TYPE                         VARCHAR(50),
     TICKER_COUPON_MATURITY           VARCHAR(100),
     SEC_DESC                         VARCHAR(1024),
     ISIN                             VARCHAR(50),
     ORIG_FACE                        DECIMAL(20,10),
     SETTLED                          DECIMAL(20,10),
     NOTIONAL_MKT_VAL                 DECIMAL(20,10),
     BASE_CURR_MKT_VAL_ACC_INT        DECIMAL(20,10),
     BASE_CURR_MKT_INT                DECIMAL(20,10),
     MATURITY_DATE                    VARCHAR(50),
     ISSUE_DATE                       VARCHAR(50),
     BASE_CURR_FX_RATE                DECIMAL(20,10),
     MKT_PRICE                        DECIMAL(20,10),
     COUPON                           VARCHAR(10),
     SNP_RATING                       VARCHAR(10),
     AS_OF_DATE                       DATE NOT NULL,
     FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED,
     UNIQUE (FUND_ID,CUSIP,AS_OF_DATE)
);

DROP TABLE ALADDIN_FUT_POS;
CREATE TABLE  ALADDIN_FUT_POS
(
     FUND_ID                          VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
     REUTER                           VARCHAR(50) NOT NULL,
     CUSIP                            VARCHAR(50) NOT NULL,
     SEC_DESC                         VARCHAR(1024),
     ORIG_FACE                        DECIMAL(20,10),
     CURR_FACE                        DECIMAL(20,10),
     CURRENCY                         VARCHAR(10),
     UNSETTLED                        DECIMAL(20,10),
     MKT_PRICE                        DECIMAL(20,10),
     COUNTER_PRTY_TIC                 VARCHAR(50),
     AS_OF_DATE                       DATE NOT NULL,
     FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED,
     UNIQUE (FUND_ID,CUSIP,AS_OF_DATE)
);

DROP TABLE FCM_NE_BALANCE_EQUITY_BY_CURRENCY;
CREATE TABLE  FCM_NE_BALANCE_EQUITY_BY_CURRENCY
(
    BAL_TYPE                          VARCHAR(10),
    SORT_LEVEL                        VARCHAR(50),
    COMPANY                           VARCHAR(50),
    FIRM                              VARCHAR(10),
    OFFICE                            VARCHAR(10),
    ACCT_NUM                          VARCHAR(50) NOT NULL ,  -- MAPS TO HEAD ACCOUNT NUMBER IN EXCEL FILE
    SALESMAN                          VARCHAR(50),
    AS_OF_DATE                        DATE NOT NULL,  -- Maps to LBDAY
    FUND_NAME                         VARCHAR(100) NOT NULL, -- MAPS TO ACCOUNTNAME NAME IN EXCEL FILE
    FUND_ID                           VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
    GROUP_ACCT_NUM                    VARCHAR(50),  -- MAPS TO  GROUPACCTNUM IN EXCEL FILE
    GROUP_FUND_NAME                   VARCHAR(50),  -- MAPS TO  GROUPACCTNAM IN EXCEL FILE
    ACCT_TYPE                         VARCHAR(10),
    CURRENCY                          VARCHAR(10),-- MAPS TO CURR IN EXCEL FILE
    BALANCE                           DECIMAL(20,10),
    FUT_INIT_MARGIN                   DECIMAL(20,10),
    FUT_MAINT_MARGIN                  DECIMAL(20,10),
    SEC_LONG_MKVAL                    DECIMAL(20,10),
    SEC_SHORT_MKVAL                    DECIMAL(20,10),
    OPT_LONG_MKVAL                    DECIMAL(20,10),
    OPT_SHORT_MKVAL                   DECIMAL(20,10),
    OPT_LONG_OTE                      DECIMAL(20,10),
    OPT_SHORT_OTE                     DECIMAL(20,10),
    NET_LIQ                           DECIMAL(20,10),
    MARGIN_EXCESS                     DECIMAL(20,10),
    MARGIN_COL_VAL                    DECIMAL(20,10),
    FUT_OTE                           DECIMAL(20,10),
    TOTAL_EQUITY                      DECIMAL(20,10),
    WITHDRAWABLE                      DECIMAL(20,10),
    TOT_CALLS                         DECIMAL(20,10),
    ACCT_CURR                         VARCHAR(10),
    MAST_CURR                         VARCHAR(10),
    CONV_ACCT                         DECIMAL(20,10),
    CONV_MAST                         DECIMAL(20,10),
    RATE_FAILS                        VARCHAR(10),
    FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED,
    -- UNIQUE (FUND_ID,ACCT_NUM,AS_OF_DATE), what is the unique key in thsi table
);

DROP TABLE FCM_MS_BALANCE_SUMMARY;
CREATE TABLE  FCM_MS_BALANCE_SUMMARY
(
    ACCT_NUM_1                        VARCHAR(50) NOT NULL ,  -- MAPS TO 0 IN EXCEL FILE
    ACCT_NUM                          VARCHAR(50) NOT NULL ,  -- MAPS TO SecuredAccount IN EXCEL FILE
    FUND_NAME                         VARCHAR(100) NOT NULL, -- MAPS TO AccountName NAME IN EXCEL FILE
    FUND_ID                           VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
    AS_OF_DATE                        DATE NOT NULL,  -- Maps to StatementDate
    CURRENCY                          VARCHAR(10),-- MAPS TO CURR IN EXCEL FILE
    SEG_IND                           VARCHAR(10), --maps to SegregatedInd
    COMB_IND                          VARCHAR(10), --maps to CombinedInd
    CONV_IND                          VARCHAR(10),-- maps to ConvertedInd
    FX_RATE                           DECIMAL(20,10),
    FX_MULTIPLIER_IND                 VARCHAR(10), -- FxMultiplierInd
    FX_BASE_CURR                      VARCHAR(10),   -- maps to FXBaseCurrency
    OPEN_BAL                          DECIMAL(20,10),-- maps to OpeningBalance
    CASH_ACTVY                        DECIMAL(20,10),-- maps to CashActivity
    FUT_COMM                          DECIMAL(20,10), -- FuturesCommission
    FUT_FEES                          DECIMAL(20,10), -- FuturesFees
    GROSS_PL                          DECIMAL(20,10), -- GrossPL
    NET_PL                            DECIMAL(20,10), -- NetPL
    CLOSE_BAL                         DECIMAL(20,10),-- ClosingBalance
    OPEN_TRADE_EQUITY                 DECIMAL(20,10),-- OpenTradeEquity
    PENDING_PS                        DECIMAL(20,10),-- PendingPS
    TOTAL_EQUITY                      DECIMAL(20,10),
    LME_DSCNT_MARGIN                  DECIMAL(20,10), -- maps to LMEDiscountMargin
    INIT_MARGIN                       DECIMAL(20,10), -- InitialMargin
    NON_CASH_COLLATERAL               DECIMAL(20,10), -- NonCashCollateral
    EQUITY_SUR_DEFICIT                DECIMAL(20,10), -- EquitySurplusDeficit
    PEND_PREMIUM                      DECIMAL(20,10), -- PendingPremium
    FORECAST_EQUITY                   DECIMAL(20,10), -- ForecastEquity
    NET_LIQ_VAL                       DECIMAL(20,10), -- NetLiquidatingValue
    MTD_NET_REALZ_OPT_PROCEEDS        DECIMAL(20,10), -- MTDNetRealizedOptionsProceeds
    MTD_NET_REALZ_FUT_PL              DECIMAL(20,10), -- MTDNetRealizedFuturePL
    PROJ_SETTLE_AMT                   DECIMAL(20,10), -- ProjectedSettlementAmt
    PROJ_VAL_DATE                     VARCHAR(50),  -- Maps to ProjectedValueDate
    PEND_NONCASH_AMT                  DECIMAL(20,10), -- PendingNonCashAmt
    CASH_NONCASH_AMT                  DECIMAL(20,10), -- CashNonCashAmt
    COLLATERAL_SUR_DEFICIT            DECIMAL(20,10), -- CollateralSurplusDeficit
    CASH_COLLATERAL_AMT               DECIMAL(20,10), -- CashCollateralAmt
    REALIZE_VM                        DECIMAL(20,10), -- RealizedVM
    VM_ADJUST                         DECIMAL(20,10), -- VMAdjustments
    TOT_NET_PL                        DECIMAL(20,10), -- TotalNetPL
    PEND_CASH                         DECIMAL(20,10), -- PendingCash
    PEND_CASH_VAL_DATE                VARCHAR(50),  -- Maps to PendingCashValueDate
    EXCESS_MARGIN_PCT                 DECIMAL(20,10),  -- Maps to ExcessMarginPercentage
    MTD_MTM_AMT                       DECIMAL(20,10), -- MTDMTMAmt
    FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED,
    -- UNIQUE (FUND_ID,ACCT_NUM,AS_OF_DATE), what is the unique key in thsi table
);



DROP TABLE FUND_NAV_DAILY_PL;
CREATE TABLE  FUND_NAV_DAILY_PL
(
    FUND_ID                           VARCHAR(50) NOT NULL, -- maps to ID in REF_FUND table
    AS_OF_DATE                        DATE NOT NULL,  -- Maps to StatementDate
    BASE_CURR                         VARCHAR(10),-- MAPS TO Base CCY IN EXCEL FILE
    NAV_BASE_CCY                      DECIMAL(20,10),  -- maps to NAV (Base CCY)
    FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED,
    UNIQUE (FUND_ID,AS_OF_DATE)

);


DROP TABLE FUND_DAILY_PL;
CREATE TABLE  FUND_DAILY_PL
(
    INVESTMENT_HLDGS VARCHAR(50) ,
    BB_TICK VARCHAR(50) ,
    STATED_MATURITY VARCHAR(50) ,
    POS_AMT VARCHAR(50) ,
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
    FOREIGN KEY (FUND_ID) REFERENCES REF_FUND(ID) NOT ENFORCED
    -- UNIQUE (FUND_ID,AS_OF_DATE)

);
