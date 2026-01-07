**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Defining adolescent psychopathology predictors - appending them to file with other covariates 
* AUTHOR: Sydney M. Adams, adapted from Kallisse Dent 
* LAST UPDATED: 12/18/2025
* INPUT FILE(S):  Wave I interview data (allwave1.xpt), Wave II interview data (wave2.xpt) 
*				  Wave IV interview data (wave4.xpt), Wave V mixed-mode survey data (wave5.xpt),
* 				  final_covariates.sas7bdat (so must run the script generating that first)				
* OUTPUT FILE(S): predictors_covariates_final.sas7bdat, and exploratory output
* RELEVANT RESULTS IN MANUSCRIPT: None
* 
**************************************************************************************************************;

*** Formats; 
proc format ; 
value sexf 
	1 = 'M'
	2 = 'F' ;
value ethnicityf 
	0 = 'Non-Hispanic' 
	1 = 'Hispanic' ; 
value racef 
	1 = 'White' 
	2 = 'Black or African American' 
	3 = 'American Indian or Native American' 
	4 = 'Asian or Pacific Islander' 
	5 = 'Other'  
	6 = 'Multiracial'; 
run; 

*** Read in covariates data file (created in script #2);

libname AHdata "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Intermediate_Data";

data covariates; 
	set AHdata.final_covariates; 
run; 

proc contents data=covariates; 
run; 

*** Read in Waves 1-2 to bring in information on prospective (CES-D) depression; 
libname wave1 xport 'P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Core Files - Wave I\Wave I In Home Interview Data\allwave1.xpt' ; 
libname wave2 xport 'P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Core Files - Wave II\Wave II In Home Interview Data\wave2.xpt' ; 

data wave1; 
	set wave1.allwave1 (keep=aid H1FS1--H1FS18); 
run; 

proc sort data=wave1; 
	by aid; 
run; *n = 20,745; 

proc freq data=wave1; 
	tables H1FS: ; 
run; 

data wave2; 
	set wave2.wave2 (keep=aid H2FS1--H2FS18 imonth2 iyear2 iday2); 
run; 

proc sort data=wave2;
	by aid; 
run; *n = 14,738; 

proc freq data=wave2; 
	tables H2FS: ; 
run; 

** Macro to calculate CESD sum score (after re-coding reverse-coded items), sum of missing items for CESD at each wave; 

%MACRO cesd_data(num);
***Create CESD sum score ; 
data wave&num._cesd; 
set wave&num. ; 

* Array to set 6,8,9 to missing; 
array cesd {18}  H&num.FS1--H&num.FS18 ; 
do i = 1 to 18 ; 
	if cesd[i] in (6,8,9) then cesd[i] = . ; 
end ; 

* Re-code H_FS4, H_FS8, H_FS11, and H_FS15, such that
    3 -> 0, 2 -> 1, 1 -> 2, and 0 -> 3; 
** first save og ('original') non-recoded, for check ;  
og_H&num.FS4 = H&num.FS4; 
og_H&num.FS8 = H&num.FS8; 
og_H&num.FS11 = H&num.FS11; 
og_H&num.FS15 = H&num.FS15; 

** then overwrite the original vars with the reverse recoded versions 
   (keeping the var name so that they can easily go into the sum() and nmiss() below); 
array recode {4} H&num.FS4 H&num.FS8 H&num.FS11 H&num.FS15; 
do i = 1 to 4 ; 
	if recode[i] = 3 then recode[i] = 0; 
	else if recode[i] = 2 then recode[i] = 1; 
	else if recode[i] = 1 then recode[i] = 2; 
	else if recode [i] = 0 then recode[i] = 3; 
end; 

* Get CESD sum score and a count of missing CESD items ; 
w&num._cesd_sum = sum(of H&num.FS1-H&num.FS18) ; 
w&num._cesd_nmiss = nmiss(of H&num.FS1-H&num.FS18) ;

* If 4+ items missing then CES-D measure is missing ; 
if  w&num._cesd_nmiss >= 4 then w&num._cesd_sum = . ; 

* Before scaling, pro-rate based on number missing ; 
w&num._cesd_prorate = (w&num._cesd_sum/(18-w&num._cesd_nmiss))*18 ; 

* Scale up to 20 (necessary to apply cut-offs to identify cases) ; 
w&num._cesd_sum_scaled = w&num._cesd_prorate*(20/18) ; 

run; 

%MEND cesd_data; 

%cesd_data(1); 
%cesd_data(2); 

** Keep just what's needed from CESD measures; 
data wave1_cesd2 ; 
	set wave1_cesd ; 
	keep aid w1_cesd_sum w1_cesd_prorate w1_cesd_sum_scaled w1_cesd_nmiss ; 
proc sort; 
	by aid; 
run; *n = 20,745; 

data wave2_cesd2 ; 
	set wave2_cesd ; 
	keep aid  w2_cesd_sum w2_cesd_prorate w2_cesd_sum_scaled w2_cesd_nmiss imonth2 iday2 iyear2 ; 
proc sort; 
	by aid; 
run; *n =  14,738; 

*** Merge CESD variables into covariates file.; 
	** Use sex-specific cut-offs to flag CESD-assessed depression at W1, W2, only 
	   for participants aged 11-18 at wave. ; 
	
data covariates_predictors1 ; 
	merge covariates (in=a) wave1_cesd2 wave2_cesd2; 
	by aid ; 
	if a; 

w2_intvw_date = mdy(imonth2, iday2, iyear2);
w2_age=floor((w2_intvw_date-w1_bdate) / 365.25);

if w1_cesd_sum_scaled ne . and w1_age < 19  then do ; /* age <19 b/c only looking at psychopathology from 11-18 */ 
	/* there are diff CES-D cutoffs for males (sex=1) vs. females (sex=2) */ 
	if w1_sex = 1 then do ; 
		if w1_cesd_sum_scaled >= 22 then w1_Depression_CESD = 1 ; else w1_Depression_CESD = 0 ; 
	end; 
	if w1_sex = 2 then do ; 
		if w1_cesd_sum_scaled >= 24  then w1_Depression_CESD = 1 ; else w1_Depression_CESD = 0 ; 
	end ; 
end; 

if w2_cesd_sum_scaled ne . and w2_age < 19  then do ; 
	if w1_sex = 1 then do ; 
		if w2_cesd_sum_scaled >= 22 then w2_Depression_CESD = 1 ; else w2_Depression_CESD = 0 ; 
	end; 
	if w1_sex = 2 then do ; 
		if w2_cesd_sum_scaled >= 24  then w2_Depression_CESD = 1 ; else w2_Depression_CESD = 0 ; 
	end ; 
end; 

/* Create indicator of meeting cesd depression at either wave 1 or wave 2 */ 
depression_cesd = (w1_depression_cesd = 1 or w2_depression_cesd=1) ; 
if w1_depression_cesd =. and w2_depression_cesd=. then depression_cesd = . ; 

run; 

** Checks; 
proc freq data=covariates_predictors1; 
	tables Depression_CESD Depression_CESD*(w1_Depression_CESD w2_Depression_CESD) 
		   w1_Depression_CESD*w2_Depression_CESD w1_age w2_age /missing; 
run; 

proc freq ; tables w1_Depression_CESD ; where w1_age >= 19 ;run; *all missing ; 
proc freq ; tables w2_depression_CESD ; where w2_age >=19  ; run; *all missing ; 

proc means data = covariates_predictors1 n nmiss min max mean stddev ; var w1_cesd_sum w1_cesd_sum_scaled w2_cesd_sum w2_cesd_sum_scaled; run; 

* look at scaled values by sex where depress criteria was met (cut-off for females was higher (24 vs. 22), so 
  should see higher minimum for females) ;
 
proc sort data = covariates_predictors1 ; by w1_sex ; run; 
proc means data = covariates_predictors1 n nmiss min max mean stddev ; var w1_cesd_sum_scaled; by w1_sex ; where w1_Depression_CESD = 1 ; run; 
proc means data = covariates_predictors1 n nmiss min max mean stddev ; var w2_cesd_sum_scaled; by w1_sex ; where w2_Depression_CESD = 1 ; run; 

*** Bring in info on retrospective mental health diagnoses 
	First from W4. Will only use W5 if W4 missing.

   Note that per this code, individuals who had a childhood MH diagnosis will have missing (not 0) for adolescent MH,  
   given ambiguity about their MH status during adolescence. One exception to that is for a sensitivity analysis, 
   we will include childhood-diagnosed ADHD (to incorporate into alternate indicators of any/externalizing psychopathology. 
; 

libname wave4 xport "P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Core Files - Wave IV\Wave IV In Home Interview Data\wave4\wave4.xpt" ; 

data wave4_mh ; 
	set wave4.wave4 (keep = aid H4ID5H H4ID6H H4ID5I H4ID6I H4ID5J H4ID6J H4ID5L H4ID6L); 
	rename H4ID5H = w4_dx_depression H4ID6H = w4_age_depression H4ID5I = w4_dx_ptsd H4ID6I = w4_age_ptsd H4ID5J = w4_dx_anxiety H4ID6J = w4_age_anxiety 
	   H4ID5L = w4_dx_adhd H4ID6L = w4_age_adhd; 
run; *n= 15,701; 
proc contents; run; 

data wave4_mh2 ; 
length w4_cat_depression w4_cat_ptsd w4_cat_anxiety w4_cat_adhd $ 15. ; 
set wave4_mh ; 
array age {4} w4_age_depression w4_age_ptsd w4_age_anxiety w4_age_adhd ; 
array dx {4} w4_dx_depression w4_dx_ptsd w4_dx_anxiety w4_dx_adhd ; 
array adol {4} w4_adol_depression w4_adol_ptsd w4_adol_anxiety w4_adol_adhd ;
array cat {4}  w4_cat_depression w4_cat_ptsd w4_cat_anxiety w4_cat_adhd ;
do i = 1 to 4 ; 
	/* set missing */ 
	if dx[i] in (6,8) then dx[i] = . ; /* 6: Refused, 8: Don't know [8 only seems used for depression, not harmful to check for all dx though] */ 
	/* note diagnosis in adolescent years, 11-18 */ 
	if age[i] >= 11 and age[i] <= 18 then adol[i] = 1 ; else adol[i] = 0 ; 
	/* note if dx was in 'child' 'adolescent' or 'adult' years */ 
	if age[i] ne . and age[i] < 11 then cat[i] = "Child" ; 
	else if 11 <= age[i] <= 18 then cat[i] = "Adolescent" ; 
	else if 18 <= age[i] <=50  then cat[i] = "Adult" ; else cat[i] = "None" ;

	/* If retro diagnosis was during childhood then code the adolescent indicator as missing*/  
	if cat[i] = "Child" then adol[i] = . ; 

	/* if missing dx, or missing age at dx, or refused/don't know age at dx, then set both indicator of adolescent dx and categorical age at dx to missing */
	if dx[i] = . or age[i] = . or age[i] in (96,98) then do; 
		adol[i] = . ; 
		cat[i] = '' ; 
	
	end; 
end ; 
proc sort ; by aid; 
run; *n=15,701 ; 

** Check frequencies of indicator of dx at adolescence, categorical indicator of age at dx. 
   Note indicators of dx at adoelscence have more missingness b/c childhood dx is treated as missing. ; 
proc freq ; tables w4_adol: w4_cat: ; run; 

proc means n nmiss; var w4_age_depression w4_age_ptsd w4_age_anxiety w4_age_adhd; 
run; 

** Add'l checks of age at dx; 
%MACRO check1(wave, dx) ; 
title "check age at dx where adolesc dx indicator = 1"; 
proc freq data = wave&wave._mh2 ; tables w&wave._age_&dx. ; where w&wave._adol_&dx. = 1 ; run; 
title "check age at dx where adolesc dx indicator = 0"; 
proc freq data = wave&wave._mh2 ; tables w&wave._age_&dx. ; where w&wave._adol_&dx. = 0 ; run; 
title "check age at dx where adolesc dx indicator = ."; 
proc freq data = wave&wave._mh2 ; tables w&wave._age_&dx.  ; where w&wave._adol_&dx. = . ; run; 
title; 
%MEND check1 ;

%check1(4, depression); 
%check1(4, ptsd); 
%check1(4, anxiety); 
%check1(4, adhd); 

*** Code alternate ADHD indicator that includes dx from age 4-18. 
	Follows similar logic to array in the larger datastep above ; 

data wave4_mh3; 
	set wave4_mh2 ; 
	if  4 <= w4_age_adhd <= 18 then w4_child_adol_adhd = 1; else w4_child_adol_adhd=0; 
	if w4_dx_adhd = . or w4_age_adhd = . or w4_age_adhd in (1,2,3,96,98) then w4_child_adol_adhd = .; 
run; 

** Checks; 
title "check age at dx where ALT adolesc adhd dx indicator = 1"; 
proc freq data=wave4_mh3 ; tables w4_age_adhd ; where w4_child_adol_adhd=1; run;
title "check age at dx where ALT adolesc adhd dx indicator = 0"; 
proc freq data=wave4_mh3; tables w4_age_adhd; where w4_child_adol_adhd=0; run;
title "check age at dx where ALT adolesc adhd dx indicator = ."; 
proc freq data=wave4_mh3; tables w4_age_adhd; where w4_child_adol_adhd=.; run; 
title; 

proc freq data=wave4_mh3 ; tables w4_adol_adhd *w4_child_adol_adhd / nopercent missing; run; 

*** Bring in Wave V data; 

libname wave5 xport "P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Core Files - Wave V\Wave V Mixed-Mode Survey Data\wave5.xpt" ; 

data wave5_mh ; 
set wave5.wave5 (keep = aid H5ID6G H5ID6GA H5ID6H H5ID6HA H5ID6I H5ID6IA H5ID6T H5ID6TA); 
rename H5ID6G = w5_dx_depression H5ID6GA = w5_age_depression H5ID6H = w5_dx_ptsd H5ID6HA = w5_age_ptsd H5ID6I = w5_dx_anxiety H5ID6IA = w5_age_anxiety 
	   H5ID6T = w5_dx_eatingdis H5ID6TA = w5_age_eatingdis; 
run; *n = 12,300 ; 

*** Create indicators of adolescent diagnosis of condition at W5, similar logic to above; 
data wave5_mh2 ;
length  w5_cat_depression w5_cat_ptsd w5_cat_anxiety w5_cat_eatingdis $ 15. ; 
set wave5_mh ; 
array age {4} w5_age_depression w5_age_ptsd w5_age_anxiety w5_age_eatingdis ; 
array dx {4} w5_dx_depression w5_dx_ptsd w5_dx_anxiety w5_dx_eatingdis ; 
array adol {4} w5_adol_depression w5_adol_ptsd w5_adol_anxiety w5_adol_eatingdis ; 
array cat {4}  w5_cat_depression w5_cat_ptsd w5_cat_anxiety w5_cat_eatingdis ;
do i = 1 to 4 ; 
	if  age[i] >= 11 and age[i] <= 18 then adol[i] = 1 ; else adol[i] = 0 ; 
	 
	if age[i] ne . and age[i] < 11 then cat[i] = "Child" ; 
	else if 11 <= age[i] < 19 then cat[i] = "Adolescent" ; 
	else if 19 <= age[i] <=50  then cat[i] = "Adult" ; else cat[i] = "None" ;

	/* If retro diagnosis was during childhood then code the adolescent indicator as missing*/ 
	if cat[i] = "Child" then adol[i] = . ; 

	if dx[i] = . or age[i] = .  then do; 
		adol[i] = . ; cat[i] = " " ; /* Values of 96, 98 weren't used in W5 */ 
	end ; 
end ; 

proc sort ; by aid; 
run; *n=12,300; 

/* Checks */
proc freq ; tables w5_adol: w5_cat: ; run;  
proc freq ; tables w5_age_depression w5_dx_depression  ; where w5_adol_depression = . ; run; 
proc freq; tables w5_age_depression ; where w5_adol_depression = . and w5_dx_depression = 1; run; 
proc freq; tables w5_age_depression ; where w5_adol_depression = . and w5_dx_depression = .;run; 

%check1(5, depression); 
%check1(5, ptsd); 
%check1(5, anxiety); 
%check1(5, eatingdis); 


*** Bring retrospective dx back in with larger cohort / covariates ; 

proc sort data = covariates_predictors1; by aid; run; 
data covariates_predictors2 ; 
merge covariates_predictors1 (in=a) wave4_mh3 (keep=aid w4_adol: w4_cat: w4_age_depression w4_child_adol_adhd w4_age_adhd)  wave5_mh2 (keep=aid w5_adol: w5_cat: w5_age_depression); 
by aid ; 
if a; 
run; 

** Checks; 
proc contents data = covariates_predictors2; run;  

proc freq data=covariates_predictors2; tables w4_cat: /missing; run;
proc freq data=covariates_predictors2; tables w4_cat: /missing; where w5_intvw_date ne .; run;
proc freq data=covariates_predictors2; tables w1_age w4_age_depression w5_age_depression / missing; run; 

proc sort data =  covariates_predictors2 out= check_dup nodupkey ; by aid ; run; *0 duplicates; 

*** Create indicators of retrospective-reported MH, only using information from W5 if there was no information from W4.

   Note, people who reported childhood-onset MH at W4 will have their indicator set as missing, but we don't want to bring
   in additional W5 data for them because they still gave us some info at W4 and we wouldn't want to override it at W5. ; 

data covariates_predictors3 ; 
set covariates_predictors2 ; 
if w4_adol_depression ne .  or w4_cat_depression = 'Child' then adol_depression = w4_adol_depression ; 
	else if w5_adol_depression ne . then adol_depression = w5_adol_depression ; 
	else adol_depression = . ; 
if w4_adol_ptsd ne . or w4_cat_ptsd = 'Child' then adol_ptsd = w4_adol_ptsd ; 
	else if w5_adol_ptsd ne . then adol_ptsd = w5_adol_ptsd ; 
	else adol_ptsd = . ; 
if w4_adol_anxiety ne . or w4_cat_anxiety = 'Child' then adol_anxiety= w4_adol_anxiety ; 
	else if w5_adol_anxiety ne . then adol_anxiety = w5_adol_anxiety ; 
	else adol_anxiety = . ; 

*New indicators of age cat at dx, using both w4 and w5; 
if w4_cat_depression ne '' then cat_depression = w4_cat_depression ; 
	else if w5_cat_depression ne '' then cat_depression = w5_cat_depression ; 
	else cat_depression = '' ; 
if w4_cat_anxiety ne '' then cat_anxiety = w4_cat_anxiety ; 
	else if w5_cat_anxiety ne '' then cat_anxiety = w5_cat_anxiety ; 
	else cat_anxiety = '' ; 
if w4_cat_ptsd ne '' then cat_ptsd = w4_cat_ptsd ; 
	else if w5_cat_ptsd ne '' then cat_ptsd = w5_cat_ptsd ; 
	else cat_ptsd = '' ; 

*Make an indicator for any prospective OR retrospective depression (not restricted by age/timing); 
depression_any = (depression_cesd = 1 or adol_depression = 1); 
if depression_cesd =. and adol_depression =. then depression_any = . ; 

*Only want to use info on retrospective depr if the reported age at dx is 2+ years from age at wave 1 ; 
	* So - create indicator of if that difference in age was >= 2 years ; 
if w4_cat_depression ne ''  then age_diff_gr2 = (abs(w4_age_depression-w1_age)>=2); 
	else if w5_cat_depression ne '' then age_diff_gr2 = (abs(w5_age_depression-w1_age)>=2); 
	else age_diff_gr2 =.; 

	* If it was, then set new var called adol_depression_agelimit to the value of retrospective adol depression; 
if age_diff_gr2 = 1 then adol_depression_agelimit = adol_depression; 
	else adol_depression_agelimit = . ; 

	* Then set new var called depression_agelimit to 1 if either the prospective depression or the (qualifying) retrospective 
		report of depression was = to 1 ; 
depression_agelimit = (depression_cesd = 1 or adol_depression_agelimit = 1); 
if depression_cesd =. and adol_depression_agelimit =. then depression_agelimit = . ; 

*For checks - create indicator of any retrospective MH dx, first including all the retrospective reports of depression,
 then just the qualifying retrospective reports of depression, then no depression at all. ; 
Adol_Any_RetroMH_incldep = (adol_depression = 1 or adol_ptsd = 1 or  adol_anxiety= 1 or  w4_adol_adhd= 1 or  w5_adol_eatingdis= 1); 
Adol_Any_RetroMH_agelimdep = (adol_depression_agelimit = 1 or adol_ptsd = 1 or  adol_anxiety= 1 or  w4_adol_adhd= 1 or  w5_adol_eatingdis= 1);
Adol_Any_RetroMH_excldep = (adol_ptsd = 1 or  adol_anxiety= 1 or  w4_adol_adhd= 1 or  w5_adol_eatingdis= 1); 

*If ALL indicators of retrosp MH are missing, set retrosp MH indicators to missing ; 
if adol_depression = . and adol_ptsd= . and  adol_anxiety= . and  w4_adol_adhd= . and  w5_adol_eatingdis= . then Adol_Any_RetroMH_incldep = . ; 
if adol_depression_agelimit = . and adol_ptsd= . and  adol_anxiety= . and  w4_adol_adhd= . and  w5_adol_eatingdis= . then Adol_Any_RetroMH_agelimdep = . ;
if adol_ptsd= . and  adol_anxiety= . and  w4_adol_adhd= . and  w5_adol_eatingdis= . then Adol_Any_RetroMH_excldep = . ;

rename w4_adol_adhd = adol_adhd w4_cat_adhd = cat_adhd w5_adol_eatingdis = adol_eatingdis w5_cat_eatingdis = cat_eatingdis 
	   w4_child_adol_adhd = alt_ch_adol_adhd ; 
run ; 

proc contents data=covariates_predictors3; run; 


*** Bring in W1 conduct disorder information.; 
	*** Note some, but not all, CD-related items were assessed at W2, so we are not using W2. ; 

data w1_conduct  ; 
set wave1.allwave1 (keep=aid H1DS2 H1DS3 H1DS5 H1DS6 H1DS7 H1DS8 H1DS9 H1DS10 H1DS11 H1CO10 H1FV7 H1FV8); 
rename H1DS2 = w1_property_damage H1DS3= w1_lying H1DS5= w1_serious_fight  H1DS6=w1_physical_harm H1DS7=w1_runaway H1DS8=w1_car_woperm H1DS9=w1_steal 
	   H1DS10=w1_breakin H1DS11=w1_threat_weapon H1CO10=w1_force_sex H1FV7=w1_gunknife H1FV8=w1_shotstab; 
proc sort ; by aid; 
run; *n =  20,745; 
proc contents; run; 

libname school xport 'P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Core Files - Wave I\Wave I In-School Questionnaire Data\Inschool.xpt' ; 

data school_conduct ; 
set school.Inschool (keep=aid S59G) ; 
rename S59G=conduct_skipschool ;
run; 

** Note some rows with missing AID are dropped here; 
proc sort nodupkey out=school_conduct2 ; by _ALL_ ; run; /* nodupkey by ALL (skip school indicator and aid) */ 
proc sort ; by aid ; 
run; *n=  85,636;

*** Create indicators corresponding to conduct disorder criteria; 
data covariates_predictors4 ; 
merge covariates_predictors3 (in=a) w1_conduct school_conduct2 ; 
by aid ; 
if a ; 

***Have to start by coding 'any' variables ; 

/* >0 indicates 1+ time */ 
w1_di_propertydam = (w1_property_damage > 0); if w1_property_damage in (.,6,8,9) then w1_di_propertydam = . ; 

/* 3 indicates 5+ times */ 
w1_di_lying = (w1_lying=3); if w1_lying in (.,6,8,9) then w1_di_lying = . ; 

/* 2,3 indicates 3-4 or 5+ times */ 
w1_di_serious_fight = (w1_serious_fight in (2,3)); if w1_serious_fight in (.,6,8,9) then w1_di_serious_fight = . ; 

/* >0 indicates 1+ time (6,8,9 missing; for w2, 7 is legit skip) */ 
w1_di_physical_harm = (w1_physical_harm >0); if w1_physical_harm in (.,6,8,9) then w1_di_physical_harm = . ; 

/* 2,3 indicates 3-4 or 5+ times */ 
w1_di_runaway= (w1_runaway in (2,3)); if w1_runaway in (.,6,8,9) then w1_di_runaway = . ; 

/* >0 indicates 1+ time */
w1_di_car_woperm = (w1_car_woperm > 0); if w1_car_woperm in (.,6,8,9) then w1_di_car_woperm = . ; 

/* >0 indicates 1+ time */ 
w1_di_steal = (w1_steal > 0); if w1_steal in (.,6,8,9) then w1_di_steal = . ;

/* >0 indicates 1+ time */ 
w1_di_breakin = (w1_breakin > 0); if w1_breakin in (.,6,8,9) then w1_di_breakin = . ;

/* >0 indicates 1+ time */ 
w1_di_threat_weapon = (w1_threat_weapon > 0); if w1_threat_weapon in (.,6,8,9) then w1_di_threat_weapon = . ;

/* if sex = male, then code forced sex var. it was not asked of females. */ 
if w1_sex = 1 then do ; 
/* Note: Not including 7 (legitimate skip) in the group for coding to . b/c those who reported no sex were not given this survey */
	w1_di_force_sex = (w1_force_sex=1) ; 
	if w1_force_sex in (.,6,8,9) then w1_di_force_sex = . ; 
end; 

/* >0 is once or more. */ 
w1_di_gunknife = (w1_gunknife > 0) ; if w1_gunknife in (.,6,8,9) then w1_di_gunknife = . ; 

/* >0 is once or more */ 
w1_di_shotstab = (w1_shotstab > 0); if w1_shotstab in (.,6,8,9) then w1_di_shotstab = . ; 

/* >2 is "2-3 days a month", "once or twice a week", "3-5 days a week", or "nearly everyday" 
For clarity I'm adding a w1_ - that's when the in-school administration happened */ 
w1_conduct_skipschool2 = (conduct_skipschool >2); if conduct_skipschool in (99,.) then w1_conduct_skipschool2 = . ; 

run; * n = 20,745 ; 

/* Check for no duplicates */ 
proc sort data = covariates_predictors4 out = check nodupkey; by aid ; run; 

/* check re-codes */ 
proc freq data = covariates_predictors4 ; tables w1_di_propertydam*w1_property_damage w1_di_lying*w1_lying 
				 w1_di_serious_fight*w1_serious_fight w1_di_physical_harm*w1_physical_harm 
				 w1_di_runaway*w1_runaway w1_di_car_woperm*w1_car_woperm 
				 w1_di_steal*w1_steal w1_di_breakin*w1_breakin w1_di_threat_weapon*w1_threat_weapon 
				 w1_di_force_sex*(w1_force_sex w1_sex) w1_di_gunknife*w1_gunknife w1_di_shotstab*w1_shotstab 
				 w1_conduct_skipschool2*conduct_skipschool /missing ; run; 

/* Forced sex not asked of females */
proc freq data=covariates_predictors4; table w1_di_force_sex*w1_sex / missing; run; 

data covariates_predictors5 ; 
set covariates_predictors4; 

***Creating final 11 indicators used in the paper, for both W1 and W2 ; 
*1. Steal - can leave as is: w1_di_steal w2_di_steal; 
*2. breaking in or use car; 
w1_breakin_usecar = (w1_di_breakin=1 or w1_di_car_woperm=1) ; 
if w1_di_breakin=. and w1_di_car_woperm=. then w1_breakin_usecar=.; 

*3. destroy property - can leave as is: w1_di_propertydam w2_di_propertydam ; 
*4. force sex - can leave as is: w1_di_force_sex w2_di_force_sex ; 
*5. use a weapon ; 
w1_use_weapon = (w1_di_gunknife=1 or w1_di_shotstab=1); 
if w1_di_gunknife=. and w1_di_shotstab=. then w1_use_weapon=.; 

*6 stealing with confrontation - w1_di_threat_weapon w2_di_threat_weapon ; 
*7. phsycially harm - can leave as is: w1_di_physical_harm w2_di_physical_harm ; 
*8. runaway = can leave as is: w1_di_runaway w2_di_runaway  ; 
*9. frequent lying - can leave as is:  w1_di_lying w2_di_lying ; 
*10. skip school - can leave as is: w1_conduct_skipschool2. Not available for w2; 
*11. physical fighting - can leave as is:  w1_di_serious_fight w2_di_serious_fight; 

***Sum the indicators ; 
w1_conduct_sum = sum(w1_di_steal, w1_breakin_usecar, w1_di_propertydam, w1_di_force_sex, w1_use_weapon, w1_di_threat_weapon, 
					w1_di_physical_harm, w1_di_runaway, w1_di_lying, w1_conduct_skipschool2, w1_di_serious_fight);

** Code missing if 20% or more of the indicators are missing (i.e., only use CD data for those 
   with at least 80% completeness, or at least 9 / 11 items (no more than 2 missing). 

   Note all females are missing 1 item (forced sex) that was not assessed of them.;

w1_conduct_miss_sum = nmiss(w1_di_steal, w1_breakin_usecar, w1_di_propertydam, w1_di_force_sex, w1_use_weapon, w1_di_threat_weapon, 
					w1_di_physical_harm, w1_di_runaway, w1_di_lying, w1_conduct_skipschool2, w1_di_serious_fight);

if  w1_conduct_miss_sum >= 3 then w1_conduct_sum2 = . ; 
else w1_conduct_sum2 = w1_conduct_sum ; 

** Now pro-rating up to 11-items.;

if w1_sex=1 then do; 
	w1_conduct_prorate = (w1_conduct_sum2 / (11-w1_conduct_miss_sum))*11; *Males have 11 poss items; 
	end; 

else if w1_sex=2 then do; 
	w1_conduct_prorate = (w1_conduct_sum2 / (10-(w1_conduct_miss_sum-1)))*11; *Females have 10 poss items (no forced sex); 
	end; 

w1_conduct_disorder = (w1_conduct_sum2 >= 3); if w1_conduct_sum2 = . then w1_conduct_disorder=.; 
w1_conduct_disorder_prorate = (w1_conduct_prorate >= 3); if w1_conduct_prorate =. then w1_conduct_disorder_prorate=.; 

** only counting adolescent CD ; 
if w1_age > 18 then do;  w1_conduct_disorder =. ; w1_conduct_disorder_prorate =. ; end; 

run; *n=20,745 ; 

proc contents data=covariates_predictors5; run; 

** Checks; 

proc freq data=covariates_predictors5; table  w1_conduct_disorder_prorate
                                              w1_conduct_disorder / missing nocol norow nopercent; 
run; 

proc freq data=covariates_predictors5; table w1_conduct_disorder*w1_conduct_disorder_prorate /missing norow nocol nopercent; run; 
proc freq data=covariates_predictors5; table w1_conduct_disorder_prorate*w1_age /missing; run; 
proc freq data=covariates_predictors5; table w1_conduct_disorder_prorate*w1_sex /nopercent nocol missing; run; 

** Note - prorating does not actually change the number of identified cases; 
proc freq data=covariates_predictors5; 
	table w1_conduct_disorder*w1_conduct_disorder_prorate / nocol norow nopercent missing; 
run; 

*** Create output dataset of adoelscent psychopathology and covariates, keeping what is needed for analyses; 
proc contents data=covariates_predictors5;
run; 

data covariates_predictors_final;
	set covariates_predictors5 (keep = aid adol_: alt_ch_adol_adhd depression_: race_sum 
							           w1_age w1_bdate w1_cog_ability w1_ses w1_ethnicity w1_race1 
									   w1_race2 w1_sex w1_conduct_disorder w1_conduct_disorder_prorate 
									   w4_age_adhd w5_age w5_intvw_date w1_cesd_sum_scaled w1_conduct_prorate) ; 

*** Any (Int or Ext) Adolesc Mental Health ; 

if (adol_adhd=1 or adol_anxiety=1 or adol_depression_agelimit=1 or adol_eatingdis=1 or adol_ptsd=1 
	or depression_cesd=1 or w1_conduct_disorder_prorate=1) then any_adol_mh=1; 
	else if (adol_adhd=. and adol_anxiety=. and adol_depression_agelimit=. and adol_eatingdis=. and adol_ptsd=.
	and depression_cesd=. and w1_conduct_disorder_prorate=.) then any_adol_mh=.; 
	else any_adol_mh=0; 

*** ALT Any Adolesc Mental Health 
	Includes childhood ADHD ; 

if (alt_ch_adol_adhd=1 or adol_anxiety=1 or adol_depression_agelimit=1 or adol_eatingdis=1 or adol_ptsd=1 
	or depression_cesd=1 or w1_conduct_disorder_prorate=1) then alt_any_adol_mh_adhd=1; 
	else if (alt_ch_adol_adhd=. and adol_anxiety=. and adol_depression_agelimit=. and adol_eatingdis=. and adol_ptsd=.
	and depression_cesd=. and w1_conduct_disorder_prorate=.) then alt_any_adol_mh_adhd=.; 
	else alt_any_adol_mh_adhd=0; 

*** Any Int Adolesc Mental Health ; 
if (adol_anxiety=1 or adol_depression_agelimit=1 or adol_eatingdis=1 or adol_ptsd=1 or depression_cesd=1) then int_adol_mh=1; 
	else if (adol_anxiety=. and adol_depression_agelimit=. and adol_eatingdis=. and adol_ptsd=. and depression_cesd=.) then int_adol_mh=.; 
	else int_adol_mh=0; 

*** Any Ext Adolesc Mental Health ; 
if (adol_adhd=1 or w1_conduct_disorder_prorate=1) then ext_adol_mh=1; 
	else if (adol_adhd=. and w1_conduct_disorder_prorate=.) then ext_adol_mh=.;
	else ext_adol_mh=0; 

*** ALT Any Ext Adolesc Mental Health 
	Includes childhood ADHD ; 
if (alt_ch_adol_adhd=1 or w1_conduct_disorder_prorate=1) then alt_ext_adol_mh_adhd=1; 
	else if (alt_ch_adol_adhd=. and w1_conduct_disorder_prorate=.) then alt_ext_adol_mh_adhd=.; 
	else alt_ext_adol_mh_adhd=0; 
run; *n=20,745; 

proc sort data=covariates_predictors_final; by aid; run; 
proc contents data=covariates_predictors_final; run;

*** OUTPUT DATA FOR SUBSEQUENT ANALYSES. ;  
libname AHdata "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Intermediate_Data" ; 

data AHdata.covariates_predictors_final; 
	* Drop non-prorated version of CD; 
	* Drop QA indicators only used for checks; 
	* Drop depression_any and adol_depression (which don't follow rule that retrosp depr only counted when 2 years from prosp assmt); 

	set covariates_predictors_final (drop= w1_conduct_disorder Adol_Any_RetroMH_agelimdep Adol_Any_RetroMH_excldep Adol_Any_RetroMH_incldep
										  depression_any adol_depression);
	/* Rename to more intuitive names */ 
	rename  depression_cesd = w1_w2_cesd_depression 
			depression_agelimit = cesd_or_agelmt_retr_depress
			adol_depression_agelimit = retr_depr_agelmtd 
			w1_conduct_disorder_prorate = w1_conduct_dis_prorated; 
run; * n=20,745; 

proc contents data=AHdata.covariates_predictors_final; run; 


