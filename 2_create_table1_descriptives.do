#delimit ;
capture clear all ;
capture log close ;
set more off ;

log using "K:\Log Files\2_create_table1_descriptives.log", replace
use "K:\Data Files\Analysis_File_MI1.dta"

/*GET SAMPLE SIZE*/
//by treatment
tab instrument if _mj==0
drop if _mj==0
//by care type
tab headstart [iw=wgt]
tab center [iw=wgt]
tab headstart center [iw=wgt]
//by race
tab black [iw=wgt]
tab white [iw=wgt]
tab hispanic [iw=wgt]
//by low income
tab low_income [iw=wgt]
//full_time center samples
tab fulltime_center [iw=wgt]
tab fulltime_center if black==1 [iw=wgt]
tab fulltime_center if hispanic==1 [iw=wgt]
tab fulltime_center if low_income==1 [iw=wgt]

/*TREATMENT V CONTROL*/
//offer
mean urban father_home teenmom other_under6 specneeds spanish hhsize hhincome married cohort dropout college black hispanic white emp2002 ft2002 econdiff2002 zdepress2002 transport quality_index fulltime_center if (instrument==1) [iw=wgt]
//no offer
mean urban father_home teenmom other_under6 specneeds spanish hhsize hhincome married cohort dropout college black hispanic white emp2002 ft2002 econdiff2002 zdepress2002 transport quality_index fulltime_center if (instrument==0) [iw=wgt]

/*SCHOOL CHOICES*/
//headstart
mean urban father_home teenmom other_under6 specneeds spanish hhsize hhincome married cohort dropout college black hispanic white emp2002 ft2002 econdiff2002 zdepress2002 transport quality_index fulltime_center if (headstart==1) [iw=wgt]
//not headstart
mean urban father_home teenmom other_under6 specneeds spanish hhsize hhincome married cohort dropout college black hispanic white emp2002 ft2002 econdiff2002 zdepress2002 transport quality_index fulltime_center if (headstart==0) [iw=wgt]
//other center
mean urban father_home teenmom other_under6 specneeds spanish hhsize hhincome married cohort dropout college black hispanic white emp2002 ft2002 econdiff2002 zdepress2002 transport quality_index fulltime_center if (center==1) [iw=wgt]
//home
mean urban father_home teenmom other_under6 specneeds spanish hhsize hhincome married cohort dropout college black hispanic white emp2002 ft2002 econdiff2002 zdepress2002 transport quality_index fulltime_center if (headstart==0 & center==0) [iw=wgt]

log close