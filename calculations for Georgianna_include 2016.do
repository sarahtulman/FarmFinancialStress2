clear
 
 set more off
 
 use "M:\NewRRED_M_drive\FEB\FarmFinancialStress\OutputData\fdicdata.dta", clear
 preserve
 
 *calculate regions matching the NASS regions in the ARMS webtool
 ***NOTE: added Alaska, Micronesia ("FM"), Guam ("GU"), Hawaii to West (not in ARMS)
 ******** added DC, Puerto Rico, US Virgin Islands to Atlantic (not in ARMS)
 
 gen region=""
 replace region= "Atlantic" if inlist(stalp,"CT","DE","KY","ME","MD","MA","NH","NJ") 
 replace region= "Atlantic" if inlist(stalp,"NY","NC","PA","RI","TN","VT","VA","WV") 
 replace region= "Atlantic" if inlist(stalp,"DC","PR","VI")
 replace region= "South" if inlist(stalp,"AL","AR","FL","GA","LA","MS","SC") 
 replace region= "Midwest" if inlist(stalp,"IL","IN","IA","MI","MN","MO","OH","WI")
 replace region= "Plains" if inlist(stalp,"KS","NE","ND","OK","SD","TX")
 replace region= "West" if inlist(stalp,"AZ","CA","CO","ID","MT","NV","NM","OR")
 replace region= "West" if inlist(stalp,"UT","WA","WY","AK","FM","GU","HI")
 
******FIRST, deal with the reporting date and narrowing it down to the relevant dates

 *create reporting date in numeric (date) format
 *NOTE: can't simply destring repdte because of the slashes, had to create a new variable

 split repdte, g(part) p("/") /*generates part1 part 2 part3 for the day, month, year*/
 *next add zeros to missing dates (so is 03 for March instead of just 3)
 forv j = 1/2 {
replace part`j' = "0" + part`j' if length(part`j')<2
}
gen tmp = part1 + part2 + part3 /*generates new temporary variable without the slashes*/
gen repdte_num=date(tmp, "MDY") /*repdte_num is the new numerical variable for reporting date*/
format repdte_num %td
drop tmp

*create a variable that is just the year
gen year= year(repdte_num)

*drop if not 4Q data (since using annual for this)
drop if part1 != "12"
/*check to make sure*/ tab repdte_num
drop part*

*drop years outside of (what Georgianna's looking at (2011-2015) plus 2016)
drop if repdte_num < td(31dec2011) | repdte_num > td(31dec2016)


 *NEXT, create sums for ag delinquency totals  
 
 *first destring numeric variables (StatTransfer somehow transferred everything over as string variables)
 *this command creates a list of all of the variables that are NOT specified below
ds name city stalp  repdte rundate bkclass address namehcr county fdicdbs fdicsupv fldoff repdte_num, not
foreach j of var `r(varlist)' {
destring `j', replace
}
 

replace p3ag=0 if p3ag==.
replace p3agsm=0 if p3agsm==.
replace p9ag=0 if p9ag==.
replace p9agsm=0 if p9agsm==.
replace naag=0 if naag==.
replace naagsm=0 if naagsm==.


replace p3reag=0 if p3reag==.
replace p9reag=0 if p9reag==.
replace nareag=0 if nareag==.


*create variables for total real estate and non-real estate ag loan delinquincies (3 mo + 9 mo + non-accrual)
gen agsum = p3ag + p3agsm + p9ag + p9agsm + naag + naagsm /*non-real estate*/
gen reagsum = p3reag + p9reag + nareag                    /*real estate*/   

save "M:\NewRRED_M_drive\FEB\FarmFinancialStress\OutputData\fdicdata_forGeorgiannaplus2016.dta", replace


/*create variable with the sum for each state in each quarter
*state
egen total_reag_statequarter=total(reagsum), by(stalp repdte_num)
egen total_ag_statequarter=total(agsum), by(stalp repdte_num)
egen total_lnag_statequarter=total(lnag), by (stalp repdte_num)
egen total_lnreag_statequarter=total(lnreag), by (stalp repdte_num)

*****delinquency % by state (variable names: sh=share)**************
gen shag= total_ag_statequarter/total_lnag_statequarter  /*NOTE TO JEFF-- these are total-over-total*/
gen shreag= total_reag_statequarter/total_lnreag_statequarter

*nation
egen total_reag_nationalquarter=total(reagsum), by( repdte_num)
egen total_ag_nationalquarter=total(agsum), by( repdte_num)
egen total_lnag_nationalquarter=total(lnag), by ( repdte_num)
egen total_lnreag_nationalquarter=total(lnreag), by ( repdte_num)

*****national delinquency % **************
gen shag_national= total_ag_nationalquarter/total_lnag_nationalquarter
gen shreag_national= total_reag_nationalquarter/total_lnreag_nationalquarter

*region
egen total_reag_regionquarter=total(reagsum), by( region repdte_num)
egen total_ag_regionquarter=total(agsum), by(region repdte_num)
egen total_lnag_regionquarter=total(lnag), by (region repdte_num)
egen total_lnreag_regionquarter=total(lnreag), by (region repdte_num)

*****regional delinquency % **************
gen shag_region= total_ag_regionquarter/total_lnag_regionquarter
gen shreag_region= total_reag_regionquarter/total_lnreag_regionquarter



*stop
*create datasets with only 1 observation per geographic area (here we're using state, as an example), with only these variables


*both (still as separate variables)
preserve
keep stalp repdte total_reag_statequarter total_ag_statequarter total_lnreag_statequarter total_lnag_statequarter shag shreag
duplicates drop
sort stalp repdte
[then you'd save it as a different file]
restore*/



restore




