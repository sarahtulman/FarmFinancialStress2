use "M:\NewRRED_M_drive\FEB\FarmFinancialStress\OutputData\fdicdata_forGeorgiannaONLY2016.dta", clear
*calculating ag + reag
egen total_reagsum_national=total(reagsum), by( repdte)
egen total_agsum_national=total(agsum), by( repdte)

egen total_reagsum_regional=total(reagsum), by( repdte region)
egen total_agsum_regional=total(agsum), by( repdte region)

preserve
keep  repdte region total_reagsum_national total_agsum_national total_reagsum_regional total_agsum_regional
duplicates drop
sort  repdte
save "M:\NewRRED_M_drive\FEB\FarmFinancialStress\OutputData\fdicdata_forGeorgiannaONLY2016_national and regional totals.dta", replace


restore
