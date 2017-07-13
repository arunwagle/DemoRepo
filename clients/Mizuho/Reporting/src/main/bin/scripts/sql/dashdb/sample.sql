CREATE TABLE  WIKI
(
     Company                  	VARCHAR(1024),
     Date                 		DATE,
     Open                       DECIMAL(31,6),
     High                    	DECIMAL(31,6),
     Low                		DECIMAL(31,6),
     Close                      DECIMAL(31,6),
     Volume						DECIMAL(31,6),
     ExDivident					DECIMAL(31,6),
     SplitRatio					DECIMAL(31,6),
     AdjOpen					DECIMAL(31,6),
     AdjHigh					DECIMAL(31,6),
     AdjLow						DECIMAL(31,6),
     AdjClose					DECIMAL(31,6),
     AdjVolume					DECIMAL(31,6)
);


CREATE TABLE  Merged
(
     Amount_Requested                  	VARCHAR(50),
     Application_Date   				DATE,
     Loan_Title   				VARCHAR(1024),
     Risk_Score   				VARCHAR(50),
     Debt_To_Income_Ratio   				VARCHAR(50),
     Zip_Code   				VARCHAR(50),
     State   				VARCHAR(50),
     Employment_Length   				VARCHAR(50),
    Policy_Code   				VARCHAR(50)
);
