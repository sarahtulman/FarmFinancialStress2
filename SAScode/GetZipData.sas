/*Save the zip file you want to work with*/
/*adding some sweet comments*/
%Let GitLocation=M:\NewRRED_M_drive\FEB\; *anytime you see "Gitlocation", replace it with that folder;

Libname ZipLib "&GitLocation.FarmFinancialStress\RawZipFiles";
Libname OutLib "&GitLocation.FarmFinancialStress\OutputData";
/*This is the list of bank descriptive variables*/
%Let BankVars=cert docket fed_rssd rssdhcr name city stalp zip repdte rundate bkclass address namehcr offdom offfor stmult specgrp subchaps county cbsa_metro cbsa_metro_name estymd insdate effdate mutual parcert trust regagnt insagnt1 fdicdbs fdicsupv fldoff fed occdist otsregnm offoa cb /*inst.webaddr*/;

/*Read in macro code to download and extract FDIC zip files*/
%include "&GitLocation.FarmFinancialStress\SAScode\GetZipMacro.sas" /Source2 /*Source2 just includings the SAS code in the log*/;
%GrabZipData();
%WorkWithZipData(Report=Small Business Loans,OutputTableName=SmallBusinessLoans);
%WorkWithZipData(Report=Net Loans and Leases,OutputTableName=NetLoansAndLeases);
%WorkWithZipData(Report=Past Due and Nonaccrual Assets,OutputTableName=PastDueNonaccrualAssets);
%WorkWithZipData(Report=Loan Charge-Offs and Recoveries,OutputTableName=LoanChargeOffsRecoveries);
*reads in the variable definitions and can be used to join (append) to the long format datasets (not doing anything with at the moment) ;
PROC IMPORT OUT=VarLookup
            	DATAFILE= "&GitLocation.FarmFinancialStress\InputData\VariableLookups.csv" 
            	DBMS=csv 
				REPLACE;
     			GETNAMES=YES;
     			DATAROW=2; 
RUN;
Proc Sql;
	Create Table OutLib.FDICdata as  
		Select 	a.cert,a.docket,a.fed_rssd,a.rssdhcr,a.name,a.city,a.stalp,a.zip,
				a.repdte,a.rundate,a.bkclass,a.address,a.namehcr,a.county,a.fdicdbs,a.fdicsupv,a.fldoff,
				a.lnreag4,a.lnreag3,a.lnreag2,a.lnreag1,a.lnag4,a.lnag3,a.lnag2,a.lnag1,
				a.lnreag4N,a.lnreag3N,a.lnreag2N,a.lnreag1N,a.lnag4N,a.lnag3N,a.lnag2N,a.lnag1N,
				b.lnlsnet,b.lnlsgr,b.lnreag,b.lnag,
				c.p3asset,c.p3reag,c.p3ag,c.p3agsm,c.p3ltot,c.p9asset,c.p9reag,c.p9ag,c.p9agsm,c.p9ltot,c.naasset,c.nareag,c.naag,c.naagsm,c.naltot,
				d.drlnls,d.drreag,d.drag,d.dragsm,d.crreag,d.crag,d.cragsm,d.ntreag,d.ntag,d.ntagsm
		From OutLib.SmallBusinessLoans a /* locally references the table as "a"*/
		Left Join OutLib.NetLoansAndLeases b
			On a.cert=b.cert and a.repdte=b.repdte
		Left Join OutLib.PastDueNonaccrualAssets c
			On a.cert=c.cert and a.repdte=c.repdte
		Left Join OutLib.LoanChargeOffsRecoveries d
			On a.cert=d.cert and a.repdte=d.repdte; *table saved as FDICdata;
Quit;