#delimit ;
capture clear all ;
capture log close ;
set more off ;

global file_dir "K:\Data Files\14800389\ICPSR_29462"
log using "K:\Log Files\1_create_analysis_files.log", replace

/***COVARIATE FILE***/
use "${file_dir}\DS0001_Covariates and Subgroup Variables\29462-0001-Data-REST.dta"

keep HSIS_CHILDID HSIS_RACNTRID HSIS_RAPROGID CHILDCOHORT CHILDRESULTGROUP D_MORACE3 D_URBAN
numlabel _all, add

//cohort
gen cohort=CHILDCOHORT
label var cohort "Child Cohort"

//treatment
recode CHILDRESULTGROUP(2=1)(3=0), gen(instrument)
label var instrument "Treatment or Control"
label define instrumentlbl 1 "treatment" 0 "control"
label values instrument instrumentlbl

//mother's race
recode D_MORACE3(1=1)(2/3=0), gen(white)
recode D_MORACE3(2=1)(1 3=0), gen(black)
recode D_MORACE3(3=1)(1/2=0), gen(hispanic)

//urban
rename D_URBAN urban

keep HSIS_CHILDID HSIS_RACNTRID HSIS_RAPROGID cohort instrument white black hispanic urban
save "K:\Data Files\Covariate_File.dta", replace
clear

/***PARENT FILES: 2002, 2003 STACKED***/
use "${file_dir}\DS0003_Fall 2002 Parent Interview\29462-0003-Data-REST.dta"
gen year=2002
save "K:\Data Files\Parent_02_Raw.dta", replace
clear
use "${file_dir}\DS0006_Spring 2003 Parent Interview\29462-0006-Data-REST"
gen year=2003
save "K:\Data Files\Parent_03_Raw.dta", replace
clear
use "K:\Data Files\Parent_02_Raw.dta"
append using "K:\Data Files\Parent_03_Raw.dta"
numlabel _all, add

//mother in household: bio/adoptive mother
foreach var of varlist P1REL1-P1REL15{
	replace `var'=. if `var'>=97
	recode `var'(1=1)(nonmissing=0), gen(`var'_mother)
}
egen mother_home = rowmax(P1REL1_mother-P1REL15_mother)

//is parent who responds the mother: bio/adoptive
recode P1RELAT(1 19=1)(nonmissing=0), gen(moth_respon)

//focal care arrangrment into dummies
recode D_FOCARR(7=1)(1/6=0)(8=.), gen(headstart)
recode D_FOCARR(1=1)(2/7=0)(8=.), gen(center)

//mother married
recode P1MARMO(1=1)(2/5=0)(7/9=.), gen(married)

//father in household: bio/adoptive
foreach var of varlist P1REL1-P1REL15{
	recode `var'(2=1)(nonmissing=0), gen(`var'_father)
}
egen father_home = rowmax(P1REL1_father-P1REL15_father)

//family income
recode P1ALLIN (99997 99998 99999=.), gen(hhincome)

//mother's work
recode P1WORKMO (1 7=1)(2=0)(3/6 8/9=0)(97/99=.), gen(ft)
recode P1WORKMO (1 2 7=1)(3/6 8/9=0)(97/99=.), gen(emp)

//mother's education
recode P1GRMO(97/99=.)(0/3=1)(4/14=0), gen(dropout)
recode P1GRMO(97/99=.)(6/14=1)(0/5=0), gen(college)

//CESD individual items
//only if mother is the respondent/mother in the home
foreach var of varlist P1BOTHR-P1NOTGO{
replace `var'=. if `var'>4
replace `var'=. if moth_respon==0
replace `var'=. if mother_home==0
}

//teen mom: gave birth at age 18 or before
recode P1BIRTH(1/18=1)(0 97/99=.)(19/46=0), gen(teenmom)

//other child under 6 (not inclusive)
foreach var of varlist P1AGE2-P1AGE15{
replace `var'=. if `var'>=97
recode `var'(0/5=1)(nonmissing=0), gen(`var'_under6)
}
egen other_under6=rowmax(P1AGE2_under6-P1AGE15_under6)

//special needs
recode P1DOC(2=0)(7/9=.), gen(specneeds)

//household size
rename P1CNTR hhsize

//home language spanish
recode P1LANHO (3=1)(97 99=.)(nonmissing=0), gen(spanish)

//econ difficulty individual items
foreach var of varlist P4RENT-P4CLOTHE{
replace `var'=. if `var'>4
replace `var'=0 if `var'==2
}

//carehours: replace homecare as 0 and divide hours by 35
recode P5SETHR (99 98=.), gen(carehours)
gen carehours35 = carehours/35
drop carehours 
rename carehours35 carehours

//create separate vars for hs_hours and center_hours
gen hs_hours = carehours
replace hs_hours=0 if headstart==0
gen c_hours = carehours 
replace c_hours=0 if center==0

//keep and reshape
keep HSIS_CHILDID year hs_hours headstart center c_hours married father_home hhincome ft emp college dropout teenmom other_under6 specneeds hhsize spanish P1BOTHR-P1NOTGO P4RENT-P4CLOTHE mother_home
reshape wide hs_hours c_hours headstart center married father_home hhincome ft emp college dropout teenmom other_under6 specneeds hhsize spanish P1BOTHR-P1NOTGO P4RENT-P4CLOTHE mother_home, i(HSIS_CHILDID) j(year)

//drop all missing
foreach var of varlist _all {
	capture assert missing(`var')
	if !_rc {
		drop `var'
		}
}

//drop 2003 vars we only use at baseline
drop married2003 father_home2003 other_under62003 specneeds2003 hhsize2003 hhincome2003 dropout2003 college2003 mother_home2003

//keep only hs_hours2003 and c_hours2003
drop hs_hours2002 c_hours2002
rename hs_hours2003 hs_hours
rename c_hours2003 c_hours

//keep only headstart2003 and center2003
drop headstart2002 center2002
rename headstart2003 headstart
rename center2003 center

//rename static vars without year
rename hhsize2002 hhsize
rename father_home2002 father_home
rename teenmom2002 teenmom 
rename other_under62002 other_under6 
rename specneeds2002 specneeds  
rename spanish2002 spanish 
rename married2002 married
rename hhincome2002 hhincome
rename dropout2002 dropout
rename college2002 college
rename mother_home2002 mother_home

//econdiff
egen econdiff2002 = rowtotal(P4RENT2002-P4CLOTHE2002), missing
egen econdiff2003 = rowtotal(P4RENT2003-P4CLOTHE2003), missing
drop P4RENT*
drop P4ELECTR*
drop P4FOOD*
drop P4CLOTHE*

//depression
egen depression2002 = rowtotal(P1BOTHR2002-P1NOTGO2002), missing
egen depression2003 = rowtotal(P1BOTHR2003-P1NOTGO2003), missing
sum depression2002
scalar mean_dep2002 = r(mean)
scalar sd_dep2002 = r(sd)
gen zdepress2002 = (depression2002-mean_dep2002)/sd_dep2002  
gen zdepress2003 = (depression2003-mean_dep2002)/sd_dep2002   

drop P1BOTHR2002-P1NOTGO2002
drop P1BOTHR2003-P1NOTGO2003
drop depression*

save "K:\Data Files\Parent_File_Wide.dta", replace
clear

erase "K:\Data Files\Parent_02_Raw.dta"
erase "K:\Data Files\Parent_03_Raw.dta"

/***CENTER AND TEACHER FILES 2003***/
use "K:\Data Files\Covariate_File.dta"
merge 1:1 HSIS_CHILDID using "K:\Data Files\Parent_File_Wide.dta"
drop _merge
merge 1:1 HSIS_CHILDID using "${file_dir}\DS0009_Spring 2003 Center Director Interview\29462-0009-Data-REST.dta"
drop _merge
merge 1:1 HSIS_CHILD using "${file_dir}\DS0007_Spring 2003 Teacher Survey\29462-0007-Data-REST.dta"
drop _merge
keep HSIS_RACNTRID HSIS_CHILDID HSIS_RAPROGID instrument headstart center C5FULL C5HSNHS C5TRANP C5NUTRIT C5HLTHSR C5VISIT C5AWARD C1GRADE C1LEAD C5ASSTCH C5CAPAC L1LETRS-L1PREPO L3LOUD-L3CALEND
numlabel _all, add

//replace as missing if not HS center, child not assigned to treatment, child not attending hs
foreach var of varlist C5HLTHSR-C5VISIT L*{
	replace `var' =. if C5HSNHS==2
	replace `var'=. if instrument==0
	replace `var'=. if headstart!=1
}

***VARS FROM CENTER DIRECTOR INTERVIEW***

//use modal value for center if center has multiple values
foreach var of varlist C5FULL-C5VISIT {
	bysort HSIS_RACNTRID: egen `var'_mode=mode(`var'),
	replace `var'=`var'_mode if `var'==.
}

//does center offer transportation
recode C5TRANP (2=0), gen(transport)

//does center offer nutrition program
recode C5NUTRIT (5=1)(0=0)(9=.), gen(nutrition)

//does center offer home visits
recode C5VISIT (2=0), gen(homevisit)

//does center offer health services
recode C5HLTHSR (4=1)(0=0)(9=.), gen(healthserv)

//center director has BA+
recode C1GRADE (1/8=0)(9/12=1)(99=.), gen(directorBA)

//above median level teachers with some certification
recode C5AWARD (998 999=.), gen(teach_cert)
sum teach_cert, detail
quietly scalar med1 = r(p50)
recode teach_cert (0/`=med1'=0)(nonmissing=1), gen(teach_cert2)

//instructor-student ratio above median
recode C1LEAD (99=.), gen(leadteach)
recode C5ASSTCH (999=.), gen(asstteach)
egen tot_teach = rowtotal(leadteach asstteach), missing
recode C5CAPAC (9999=.), gen(capacity) 
gen stu_teach = capacity/tot_teach
quietly sum stu_teach, detail
scalar med2 = r(p50)
recode stu_teach (`=med2'/max=0)(nonmissing=1), gen(stu_teach2)

//headstart center fulltime or not
recode C5FULL(1=1)(0=0)(9=.), gen(fulltime_center)

***VARS FROM TEACHER SURVEY***

//not ascertained as missing
foreach var of varlist L*{
replace `var'=. if `var'==9
}

//get mean for each center and use the mean
//because multiple classrooms in each center
foreach var of varlist L* {
	bysort HSIS_RACNTRID: egen `var'_mean=mean(`var'),
	replace `var'=`var'_mean
}

//activity level above or below median: activities2
egen activities = rowmean(L1LETRS-L1PREPO L3LOUD-L3CALEND)
quietly sum activities, detail 
scalar med3 = r(p50)
recode activities (0/`=med3'=0)(nonmissing=1), gen(activities2)

//create index by summing up dummies
gen quality_index = activities2+nutrition+healthserv+homevisit+directorBA+teach_cert2+stu_teach2

drop L* C*

keep HSIS_CHILDID transport quality_index fulltime_center

save "K:\Data Files\Center_File.dta", replace
clear

/***MERGE Covariate, Parent, Center, Weights***/
use "K:\Data Files\Covariate_File.dta"
merge 1:1 HSIS_CHILDID using "K:\Data Files\Parent_File_Wide.dta"
drop _merge
merge 1:1 HSIS_CHILDID using "K:\Data Files\Center_File.dta"
drop _merge
merge 1:1 HSIS_CHILDID using "${file_dir}\DS0030_Weights Codebook\29462-0030-Data-REST.dta"
drop _merge
keep HSIS_RAPROGID-quality_index CHILDBASEWT
save "K:\Data Files\Analysis_File_Merged_NoMI.dta", replace

/***IMPUTE CARE ARRANGEMENT***/
use "K:\Data Files\Analysis_File_Merged_NoMI.dta"

//destring
destring cohort, replace

//for care_arrangement file, drop hours vars
drop hs_hours c_hours

//drop if mother not home parent mother not in the home
keep if mother_home==1 //keep 3406 observations
drop mother_home

//multiple imputation
misstable sum
mi set mlong
mi register imputed married hhincome ft* emp* dropout college teenmom other_under6 spanish headstart center econdiff* zdepress* transport fulltime_center quality_index	
mi register regular white black hispanic urban cohort instrument hhsize specneeds father_home HSIS_CHILDID HSIS_RACNTRID HSIS_RAPROGID CHILDBASEWT
mi describe

mi impute chain ///
	(logit, include(i.black i.white i.hispanic i.urban i.cohort c.hhsize i.specneeds i.instrument)) ///
	dropout college headstart center fulltime_center married teenmom other_under6 spanish transport ft2002 ft2003 emp2002 emp2003 ///
	(pmm, include(i.black i.white i.hispanic i.urban i.cohort c.hhsize i.specneeds i.instrument) knn(10)) ///
	hhincome zdepress2002 zdepress2003 econdiff2002 econdiff2003 quality_index ///
	, add(20) rseed(54645) augment
	
mi export ice, clear

//create wgt for descriptives
gen wgt = 1/20

//create low income dummy
sum hhincome, detail
quietly scalar med4 = r(p50)
recode hhincome(0/`=med4'=1)(nonmissing=0), gen(low_income)

save "K:\Data Files\Analysis_File_MI1.dta", replace
clear

/***IMPUTE CARE HOURS***/
use "K:\Data Files\Analysis_File_Merged_NoMI.dta"

//destring
destring cohort, replace

//drop if mother not home parent mother not in the home
keep if mother_home==1
drop mother_home

//drop headstart and center dummies
drop headstart center

//multiple imputation
misstable sum
mi set mlong
mi register imputed married hhincome ft* emp* dropout college teenmom other_under6 spanish econdiff* zdepress* transport quality_index hs_hours c_hours fulltime_center	
mi register regular white black hispanic urban cohort instrument hhsize specneeds father_home HSIS_CHILDID HSIS_RACNTRID HSIS_RAPROGID CHILDBASEWT
mi describe
mi impute chain ///
	(logit, include(i.black i.white i.hispanic i.urban i.cohort c.hhsize i.specneeds i.instrument)) ///
	dropout college married teenmom other_under6 spanish transport ft2002 ft2003 emp2002 emp2003 fulltime_center ///
	(pmm, include(i.black i.white i.hispanic i.urban i.cohort c.hhsize i.specneeds i.instrument) knn(10)) ///
	hhincome zdepress2002 zdepress2003 econdiff2002 econdiff2003 quality_index hs_hours c_hours ///
	, add(20) rseed(54645) augment	
mi export ice, clear

//create wgt for descriptives
gen wgt = 1/20

//create low income dummy
sum hhincome, detail
quietly scalar med4 = r(p50)
recode hhincome(0/`=med4'=1)(nonmissing=0), gen(low_income)

save "K:\Data Files\Analysis_File_MI2.dta", replace
clear

erase "K:\Data Files\Analysis_File_Merged_NoMI.dta"
erase "K:\Data Files\Center_File.dta"
erase "K:\Data Files\Parent_File_Wide.dta"
erase "K:\Data Files\Covariate_File.dta"

log close