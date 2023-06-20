#delimit ;
capture clear all ;
capture log close ;
set more off ;

global file_dir "K:\Data Files"

log using "K:\Log Files\3_create_table2_total_sample.log", replace
use "${file_dir}\Analysis_File_MI1.dta"

global outcomes emp ft econdiff zdepress
global covs urban cohort father_home teenmom other_under6 specneeds spanish married dropout college hhsize hhincome transport quality_index fulltime_center black hispanic 
foreach v in $covs {
    quietly gen instrumentX`v' = instrument*`v'
}

/*CREATE RESIDUALS*/
//ITT
foreach v in $outcomes {
	quietly gen `v'_itt_resid=.
	forval x=0/20 {
		quietly reg `v'2002 instrument $covs if _mj==`x', robust
		quietly predict rvar, resid
		quietly replace `v'_itt_resid=rvar if _mj==`x'
		drop rvar
		}
	}

//IV
foreach v in $outcomes {
	quietly gen `v'_iv_resid=.
	forval x=0/20 {
		quietly ivregress 2sls `v'2002 $covs (headstart=instrument) if _mj==`x', robust
		quietly predict rvar, resid
		quietly replace `v'_iv_resid=rvar if _mj==`x'
		drop rvar
		}
	}
	
//SUBLATE
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

/*ESTIMATE EFFECTS*/
use "${file_dir}\Analysis_Temp.dta", clear
mi import ice

//ITT
foreach v in $outcomes{
	mi estimate: reg `v'2003 instrument $covs `v'_itt_resid, robust
}

//FIRST STAGE F TEST
//for iv
quietly mi estimate, post: reg headstart instrument $covs, robust
mi test instrument
//for sublate - hs
quietly mi estimate, post: reg headstart instrument* $covs, robust
mi test instrument instrumentXurban instrumentXcohort instrumentXfather_home instrumentXteenmom instrumentXother_under6 instrumentXspecneeds instrumentXspanish instrumentXmarried instrumentXdropout instrumentXcollege instrumentXhhsize instrumentXhhincome instrumentXblack instrumentXhispanic instrumentXtransport instrumentXquality_index instrumentXfulltime_center

//IV
foreach v in $outcomes {
	mi estimate, cmdok: ivregress 2sls `v'2003 $covs `v'_iv_resid (headstart=instrument), robust
}

//SUBLATE
foreach v in $outcomes {
	mi estimate, cmdok: ivregress 2sls `v'2003 $covs `v'_sublate_resid (headstart center=instrument*), robust
}

erase "${file_dir}\Analysis_Temp.dta"

log close