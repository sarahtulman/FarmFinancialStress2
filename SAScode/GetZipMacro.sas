
*Get the release dates;
filename RawDates url "https://www5.fdic.gov/sdi/download_large_list_outside.asp";
data RawDates_achive(keep=zipfile Count);
	length zipfile $200;
	infile RawDates length=len lrecl=32767;
	input line $varying32767. len;
	*all the file names end with .zip;
	if find(line,".zip") then do;
		Count+1;
		*get the string ending with .zip and enclosed by quotation marks;
		*scan the line for the 4th single quote- returns the info starting at that point; 
		*then substring the returned code- start at 30th character, go for 8 characters;
		*will return just the date (example 20170331);
		zipfile=substr(scan(line,4,"'"),30,8);
		*Make a macro variable for each release date: Date1, Date2, etc.;
		*the final Datecount will equal the total number of dates that are available on FDIC website;
		call symputx('Date'||left(Count),zipfile);
		call symputx('DateCount',Count); *creates a macro variable that is the count of how many dates (automated-- how many are on FDIC website);
		output;
	end;
run;
*display (print out) all of the macro variables and the final datecount macro variable (total # of quarters);
%Put _global_;
%macro GrabZipData();
	*do loop here to loop over the needed release dates and grab data;
	*there will be a pop-up asking this;
	%if %Upcase(&Download_Most_Recent_Only)=YES %Then %Do;
		%Let DownloadCount=1;
	%End;
	%else %Do;
		%Let DownloadCount=&DateCount;
	%End;
	%Do i=1 %To &DownloadCount;
	*marker for how many you have done so far out of total;
	%Put (&i of &DownloadCount) Reporting date: &&Date&i;
	*another pop-up question asking if we want to download anything at all;
		%if %Upcase(&UseApi)=YES %Then %Do;
			filename RawZip "&GitLocation.FarmFinancialStress\RawZipFiles\All_Reports_&&Date&i";
			Proc http 
				url="https://www5.fdic.gov/sdi/Resource/AllReps/All_Reports_&&Date&i...zip"
				out=Rawzip;
			Run;
			*requires you to combine years for each report (for example: net loans and leases);
			%Let CombineYears=Yes; *overwrites old files;
		%End;
	%End;
%Mend;
%macro WorkWithZipData(Report=,OutputTableName=); *dives into zip file and pulls out only the indicated file;
	%Do i=1 %To &DateCount;
		%if %Upcase(&CombineYears)=YES %Then %Do;
		%Put (&i of &DateCount) Report: &Report Reporting date: &&Date&i;
			/*Create a filename "inzip" for the saved zip file*/
			filename inzip ZIP "&GitLocation.FarmFinancialStress\RawZipFiles\All_Reports_&&Date&i";
			 

			/* identify a temp folder in the WORK directory to put that file */
			filename xl "%sysfunc(getoption(work))/All_Reports_&&Date&i.._&Report..csv" ;
			
			*code to pull out the individual csv files that we want;
			data _null_; *indicates that using a temp file;
			   /* using member syntax here */
			   infile inzip(All_Reports_&&Date&i.._&Report..csv) 
			       lrecl=256 recfm=F length=length eof=eof unbuf;
		*reads into temporary location;
				file xl lrecl=256 recfm=N;
			   input;
			   put _infile_ $varying256. length;
			   return;
			 eof:
			   stop;
			run; *the piece above converts it into a format that SAS understands;
			 
			proc import 
				datafile=xl 
				dbms=csv 
				out=&OutputTableName&&Date&i
				replace; *reads in xl file as if it's csv, spits it out as SAS dataset;
			run;
	/*		Combine all the quarterly datasets into one big dataset*/
			%If &i=1 %Then %Do;
	/*			If its the first dataset create the base file dataset*/
				Proc Sql;
					Create Table &OutputTableName as
						Select *
						From &OutputTableName&&Date&i;
				Quit;
			%End;
			%Else %Do;
	/*		Otherwise append the new file to the base dataset*/
				Proc Sql;
					Create Table &OutputTableName as
						Select *
						From &OutputTableName
						outer union corr
						Select *
						From &OutputTableName&&Date&i;
				Quit;
			%End;
			/*Delete the temp annual table.*/
			PROC DATASETS NOLIST;
				DELETE &OutputTableName&&Date&i;
			Run;quit;
			Proc sort data=&OutputTableName (drop="inst.webaddr"N)
					out=OutLib.&OutputTableName (compress=yes index=(cert repdte)); *moves from work area to outputdata folder;
			by &BankVars;
		Run;
		%End;
	%End;
	%if %Upcase(&TransposeData)=YES %Then %Do; *transposing creates long format, which has an advantage for data storage, Tableau filtering (can also handle wide format);
		Proc Sql noprint; *this names the columns in the wide format, need these before transposing;
			Select 	name into :Columns separated by " "
				From dictionary.columns
				Where memname in ("%UpCase(&OutputTableName)");
		Quit;
		/*Proc transpose converts from wide to long format*/
		Proc Transpose 	data=OutLib.&OutputTableName
						Out=OutLib.&OutputTableName.L (where=(Col1 ne "") compress=yes);
			By &BankVars;
			Var %sysfunc(tranwrd(&Columns,&BankVars,));
		Run;
	%End;	
%Mend;