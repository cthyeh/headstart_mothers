#delimit ;
capture clear all ;
capture log close ;
set more off ;

global file_dir "K:\Data Files"

log using "K:\Log Files\4_create_table3_by_race.log", replace
use "${file_dir}\Analysis_File_MI1.dta"

global outcomes emp ft econdiff zdepress
global covs urban cohort father_home teenmom other_under6 specneeds spanish married dropout college hhsize hhincome transport quality_index fulltime_center
foreach v in $covs {
    quietly gen instrumentX`v' = instrument*`v'
}
global race black white hispanic

/*CREATE RESIDUALS*/
//ITT
foreach r in $race {
	foreach v in $outcomes {
		quietly gen `v'_itt_resid_`r'=.
		forval x=0/20 {
			quietly reg `v'2002 instrument $covs if (_mj==`x' & `r'==1), robust
			quietly predict rvar, resid
			quietly replace `v'_itt_resid_`r'=rvar if (_mj==`x' & `r'==1)
			drop rvar
			}
		}
}

//IV 
foreach r in $race {
	foreach v in $outcomes {
		quietly gen `v'_iv_resid_`r'=.
		forval x=0/20 {
			quietly ivregress 2sls `v'2002 $covs (headstart=instrument) if (_mj==`x' & `r'==1), robust
			quietly predict rvar, resid
			quietly replace `v'_iv_resid_`r'=rvar if (_mj==`x' & `r'==1)
			drop rvar
			}
		}
}

//SUBLATE
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

/*ESTIMATE EFFECTS*/
use "${file_dir}\Analysis_Temp.dta", clear
mi import ice

//ITT
foreach r in $race {
	ds `r'
	foreach v in $outcomes {
		mi estimate: reg `v'2003 instrument $covs `v'_itt_resid_`r' if `r'==1, robust
		}
}

//IV
foreach r in $race {
	ds `r'
	foreach v in $outcomes {
		mi estimate, cmdok: ivregress 2sls `v'2003 $covs `v'_iv_resid_`r' (headstart=instrument) if `r'==1, robust
		}
}

//SUBLATE
foreach r in $race {
	ds `r'
	foreach v in $outcomes {
		mi estimate, cmdok: ivregress 2sls `v'2003 $covs `v'_sublate_resid_`r' (headstart center=instrument*) if `r'==1, robust
		}
}

erase "${file_dir}\Analysis_Temp.dta"

log close