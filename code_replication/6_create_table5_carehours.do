#delimit ;
capture clear all ;
capture log close ;
set more off ;

log using "K:\Log Files\6_create_table5_carehours.log", replace

global file_dir "K:\Data Files"
global outcomes emp ft econdiff zdepress

/******************
BY HOURS (HS_HOURS)
******************/

/***TOTAL SAMPLE***/
use "${file_dir}\Analysis_File_MI2.dta"
global covs urban cohort father_home teenmom other_under6 specneeds spanish married dropout college hhsize hhincome transport quality_index fulltime_center black hispanic 
foreach v in $covs {
    quietly gen instrumentX`v' = instrument*`v'
}
//IV RESIDS
foreach v in $outcomes {
	quietly gen `v'_iv_resid=.
	forval x=0/20 {
		quietly ivregress 2sls `v'2002 $covs (hs_hours=instrument*) if _mj==`x', robust
		quietly predict rvar, resid
		quietly replace `v'_iv_resid=rvar if _mj==`x'
		drop rvar
		}
	}
save "${file_dir}\Analysis_Temp.dta", replace
clear
//IV ESTIMATE
use "${file_dir}\Analysis_Temp.dta", clear
mi import ice
foreach v in $outcomes {
	mi estimate, cmdok: ivregress 2sls `v'2003 $covs `v'_iv_resid (hs_hours=instrument*), robust
}
erase "${file_dir}\Analysis_Temp.dta"
clear

/***BY RACE***/
use "${file_dir}\Analysis_File_MI2.dta"
global covs urban cohort father_home teenmom other_under6 specneeds spanish married dropout college hhsize hhincome transport quality_index fulltime_center
global race black white hispanic
foreach v in $covs {
    quietly gen instrumentX`v' = instrument*`v'
}
//IV RESIDS
foreach r in $race {
	foreach v in $outcomes {
		quietly gen `v'_iv_resid_`r'=.
		forval x=0/20 {
			quietly ivregress 2sls `v'2002 $covs (hs_hours=instrument*) if (_mj==`x' & `r'==1), robust
			quietly predict rvar, resid
			quietly replace `v'_iv_resid_`r'=rvar if (_mj==`x' & `r'==1)
			drop rvar
			}
		}
}
save "${file_dir}\Analysis_Temp.dta", replace
clear
//IV ESTIMATE
use "${file_dir}\Analysis_Temp.dta", clear
mi import ice
foreach r in $race {
	ds `r'
	foreach v in $outcomes {
		mi estimate, cmdok: ivregress 2sls `v'2003 $covs `v'_iv_resid_`r' (hs_hours=instrument*) if `r'==1, robust
		}
}
erase "${file_dir}\Analysis_Temp.dta"
clear

/****BY INCOME***/
use "${file_dir}\Analysis_File_MI2.dta"
global covs urban cohort father_home teenmom other_under6 specneeds spanish married dropout college hhsize hhincome transport quality_index fulltime_center black hispanic 
foreach v in $covs {
    quietly gen instrumentX`v' = instrument*`v'
}
//IV RESIDS
forval i=0/1 {
	foreach v in $outcomes {
		quietly gen `v'_iv_resid_`i'=.
		forval x=0/20 {
			quietly ivregress 2sls `v'2002 $covs (hs_hours=instrument*) if (_mj==`x' & low_income ==`i'), robust
			quietly predict rvar, resid
			quietly replace `v'_iv_resid_`i'=rvar if (_mj==`x' & low_income ==`i')
			drop rvar
			}
		}
}
save "${file_dir}\Analysis_Temp.dta", replace
clear
//IV ESTIMATE
use "${file_dir}\Analysis_Temp.dta", clear
mi import ice
forval i=0/1 {
	di `i'
	foreach v in $outcomes {
		mi estimate, cmdok esampvaryok: ivregress 2sls `v'2003 $covs `v'_iv_resid_`i' (hs_hours=instrument*) if low_income ==`i', robust
			}
		}
erase "${file_dir}\Analysis_Temp.dta"
clear

/*******************
FULL TIME CENTER==1
********************/

/***TOTAL***/
use "${file_dir}\Analysis_File_MI1.dta"
global covs urban cohort father_home teenmom other_under6 specneeds spanish married dropout college hhsize hhincome black hispanic transport quality_index
//IV RESIDS
foreach v in $outcomes {
	quietly gen `v'_iv_resid=.
	forval x=0/20 {
		quietly ivregress 2sls `v'2002 $covs (headstart=instrument) if (_mj==`x' & fulltime_center==1), robust
		quietly predict rvar, resid
		quietly replace `v'_iv_resid=rvar if (_mj==`x' & fulltime_center==1)
		drop rvar
		}
	}
save "${file_dir}\Analysis_Temp.dta", replace
clear
//IV ESTIMATE
use "${file_dir}\Analysis_Temp.dta", clear
mi import ice
foreach v in $outcomes {
	mi estimate, cmdok esampvaryok: ivregress 2sls `v'2003 $covs `v'_iv_resid (headstart=instrument) if (fulltime_center==1), robust
}
erase "${file_dir}\Analysis_Temp.dta"
clear

/***BY RACE***/
use "${file_dir}\Analysis_File_MI1.dta"
global covs urban cohort father_home teenmom other_under6 specneeds spanish married dropout college hhsize hhincome transport quality_index
global race black white hispanic

//IV RESIDS
foreach r in $race {
	foreach v in $outcomes {
		quietly gen `v'_iv_resid_`r'=.
		forval x=0/20 {
			quietly ivregress 2sls `v'2002 $covs (headstart=instrument) if (_mj==`x' & `r'==1 & fulltime_center==1), robust
			quietly predict rvar, resid
			quietly replace `v'_iv_resid_`r'=rvar if (_mj==`x' & `r'==1 & fulltime_center==1)
			drop rvar
			}
		}
}
save "${file_dir}\Analysis_Temp.dta", replace
clear
//IV ESTIMATE
use "${file_dir}\Analysis_Temp.dta", clear
mi import ice
foreach r in $race {
	ds `r'
	foreach v in $outcomes {
		mi estimate, cmdok esampvaryok: ivregress 2sls `v'2003 $covs `v'_iv_resid_`r' (headstart=instrument) if (`r'==1 & fulltime_center==1), robust
		}
}

/***BY INCOME****/
use "${file_dir}\Analysis_File_MI1.dta"
global covs urban cohort father_home teenmom other_under6 specneeds spanish married dropout college hhsize hhincome black hispanic transport quality_index
//IV RESIDS
forval i=0/1 {
	foreach v in $outcomes {
		quietly gen `v'_iv_resid_`i'=.
		forval x=0/20 {
			quietly ivregress 2sls `v'2002 $covs (headstart=instrument) if (_mj==`x' & low_income==`i' & fulltime_center==1), robust
			quietly predict rvar, resid
			quietly replace `v'_iv_resid_`i'=rvar if (_mj==`x' & low_income==`i' & fulltime_center==1)
			drop rvar
			}
		}
}
save "${file_dir}\Analysis_Temp.dta", replace
clear
//IV ESTIMATE
use "${file_dir}\Analysis_Temp.dta", clear
mi import ice
forval i=0/1 {
	di `i'
	foreach v in $outcomes {
		mi estimate, cmdok esampvaryok: ivregress 2sls `v'2003 $covs `v'_iv_resid_`i' (headstart=instrument) if (low_income==`i' & fulltime_center==1), robust
			}
		}
erase "${file_dir}\Analysis_Temp.dta"
clear

log close