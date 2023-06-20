#delimit ;
capture clear all ;
capture log close ;
set more off ;

log using "K:\Log Files\appendix\2_create_tableS1_center_sublate.log", replace

global file_dir "K:\Data Files"
global outcomes emp ft econdiff zdepress

/*TOTAL*/
use "${file_dir}\Analysis_File_MI3.dta"
global covs urban cohort father_home teenmom other_under6 specneeds spanish married dropout college hhsize hhincome transport quality_index fulltime_center black hispanic 
foreach v in $covs {
    quietly gen instrumentX`v' = instrument*`v'
}
//RESID
foreach v in $outcomes {
	quietly gen `v'_sublate_resid=.
	forval x=0/20 {
		quietly ivregress 2sls `v'2002 $covs (headstart center=instrument*) if _mj==`x', robust
		quietly predict rvar, resid
		quietly replace `v'_sublate_resid=rvar if _mj==`x'
		drop rvar
		}
	}
save "${file_dir}\Analysis_Temp.dta", replace
clear
//ESTIMATE
use "${file_dir}\Analysis_Temp.dta", clear
mi import ice
foreach v in $outcomes {
	mi estimate, cmdok: ivregress 2sls `v'2003 $covs `v'_sublate_resid (headstart center=instrument*), robust
}
erase "${file_dir}\Analysis_Temp.dta"
clear

/*BY RACE*/
use "${file_dir}\Analysis_File_MI3.dta"
global covs urban cohort father_home teenmom other_under6 specneeds spanish married dropout college hhsize hhincome transport quality_index fulltime_center
foreach v in $covs {
    quietly gen instrumentX`v' = instrument*`v'
}
global race black white hispanic
//RESID
foreach r in $race {
	foreach v in $outcomes {
		quietly gen `v'_sublate_resid_`r'=.
		forval x=0/20 {
			quietly ivregress 2sls `v'2002 $covs (headstart center=instrument*) if (_mj==`x' & `r'==1), robust
			quietly predict rvar, resid
			quietly replace `v'_sublate_resid_`r'=rvar if (_mj==`x' & `r'==1)
			drop rvar
			}
		}
}
save "${file_dir}\Analysis_Temp.dta", replace
clear
//ESTIMATE
use "${file_dir}\Analysis_Temp.dta", clear
mi import ice
foreach r in $race {
	ds `r'
	foreach v in $outcomes {
		mi estimate, cmdok: ivregress 2sls `v'2003 $covs `v'_sublate_resid_`r' (headstart center=instrument*) if `r'==1, robust
		}
}
erase "${file_dir}\Analysis_Temp.dta"
clear

/*BY INCOME*/
use "${file_dir}\Analysis_File_MI3.dta"
global covs urban cohort father_home teenmom other_under6 specneeds spanish married dropout college hhsize hhincome transport quality_index fulltime_center black hispanic 
foreach v in $covs {
    quietly gen instrumentX`v' = instrument*`v'
}
//RESID
global subset low_income
forval i=0/1 {
	foreach v in $outcomes {
		quietly gen `v'_sublate_resid_`i'=.
		forval x=0/20 {
			quietly ivregress 2sls `v'2002 $covs (headstart center=instrument*) if (_mj==`x' & $subset ==`i'), robust
			quietly predict rvar, resid
			quietly replace `v'_sublate_resid_`i'=rvar if (_mj==`x' & $subset ==`i')
			drop rvar
			}
		}
}
save "${file_dir}\Analysis_Temp.dta", replace
clear
//ESTIMATE
use "${file_dir}\Analysis_Temp.dta", clear
mi import ice
forval i=0/1 {
	di `i'
	foreach v in $outcomes {
		mi estimate, cmdok esampvaryok: ivregress 2sls `v'2003 $covs `v'_sublate_resid_`i' (headstart center=instrument*) if $subset ==`i', robust
			}
		}	
erase "${file_dir}\Analysis_Temp.dta"
clear

log close