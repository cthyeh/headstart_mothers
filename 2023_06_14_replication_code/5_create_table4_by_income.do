#delimit ;
capture clear all ;
capture log close ;
set more off ;

global file_dir "K:\Data Files"

log using "K:\Log Files\5_create_table4_by_income.log", replace
use "${file_dir}\Analysis_File_MI1.dta"

global outcomes emp ft econdiff zdepress
global covs urban cohort father_home teenmom other_under6 specneeds spanish married dropout college hhsize hhincome transport quality_index fulltime_center black hispanic 
foreach v in $covs {
    quietly gen instrumentX`v' = instrument*`v'
}
global subset low_income

/*CREATE RESIDUALS*/
//ITT
forval i=0/1 {
	foreach v in $outcomes {
		quietly gen `v'_itt_resid_`i'=.
		forval x=0/20 {
			quietly reg `v'2002 instrument $covs if (_mj==`x' & $subset ==`i'), robust
			quietly predict rvar, resid
			quietly replace `v'_itt_resid_`i'=rvar if (_mj==`x' & $subset==`i')
			drop rvar
			}
		}
}

//IV 
forval i=0/1 {
	foreach v in $outcomes {
		quietly gen `v'_iv_resid_`i'=.
		forval x=0/20 {
			quietly ivregress 2sls `v'2002 $covs (headstart=instrument) if (_mj==`x' & $subset ==`i'), robust
			quietly predict rvar, resid
			quietly replace `v'_iv_resid_`i'=rvar if (_mj==`x' & $subset ==`i')
			drop rvar
			}
		}
}

//SUBLATE
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

/*ESTIMATE EFFECTS*/
use "${file_dir}\Analysis_Temp.dta", clear
mi import ice

//ITT
forval i=0/1 {
	di `i'
	foreach v in $outcomes {
		mi estimate, esampvaryok: reg `v'2003 instrument $covs `v'_itt_resid_`i' if $subset ==`i', robust
			}
		}

//IV
forval i=0/1 {
	di `i'
	foreach v in $outcomes {
		mi estimate, cmdok esampvaryok: ivregress 2sls `v'2003 $covs `v'_iv_resid_`i' (headstart=instrument) if $subset ==`i', robust
			}
		}

//SUBLATE
forval i=0/1 {
	di `i'
	foreach v in $outcomes {
		mi estimate, cmdok esampvaryok: ivregress 2sls `v'2003 $covs `v'_sublate_resid_`i' (headstart center=instrument*) if $subset ==`i', robust
			}
		}
		
erase "${file_dir}\Analysis_Temp.dta"

log close