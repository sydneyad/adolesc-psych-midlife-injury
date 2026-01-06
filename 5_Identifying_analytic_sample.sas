**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Deriving the analytic samples 
* AUTHOR: Sydney M. Adams
* LAST UPDATED: 1/5/2026 
* INPUT FILE(S):  covariates_predictors_final.sas7bdat, flag_missing_designvars.sas7bdat, 
* 				  w5_outcomes_final.sas7bdat (must run scripts 1-4 before this one!) 
* OUTPUT FILE(S): AHdata.analytic.sas7bdat, startingpop_to_analyticsample.xlsx
* RELEVANT RESULTS IN MANUSCRIPT: Figure S1 (Deriving the Primary Analytic Samples) 
*
**************************************************************************************************************;

libname AHdata "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Intermediate_Data";

/* formats */
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
value debt 
	0="None"
	1="< $10,000"
	2="$10,000-$24,999"
	3="$25,000-$49,999"
	4="$50,000-$99,999"
	5="$100,000-$249,999"
	6="$250,000-$499,999"
	7="$500,000-$999,999"
	8="$1,000,000+"; 
run;

data all_w5; 
	set AHdata.flag_missing_designvars; *n=12,300, this is a dataset w/ 1 row per participant at W5, info on the design vars; 
run; 

/* STEP ONE. Moving from total AH Wave V Pop. to Only Those w/ Non-Miss Design Vars. 
   -and-
   STEP TWO. Flag those missing on any injurt outcome as in_analytic=0 */

proc freq data=all_w5; table missing_design_vars; run; *12,057 w/ non-missing design vars ; 

proc contents data=AHdata.w5_outcomes_final; run; *n=12,300, this is a dataset w/ outcome info for everyone in W5 ; 

/* left join design vars table on outcomes table - only keep rows w/ non-miss design vars.
   N=12,057 is the 'starting population' when it comes to getting correct standard error estimates; they
   all need to be kept in the dataset. */ 

proc sql; 
	create table starting_pop as 
	select * from all_w5 (where=(missing_design_vars=0)) s
	left join AHdata.w5_outcomes_final o 
	on s.aid=o.aid ; 
	quit; 
run; *n=12,057; 

	/* In parallel - keep a version that does NOT drop those with missing design vars. This is for sib analysis. */
	proc sql; 
		create table starting_pop_sib as 
		select * from all_w5 s
		left join AHdata.w5_outcomes_final o 
		on s.aid=o.aid; 
		quit;
	run; *n=12,300; 

/* now flag those missing on any inj type */ 
proc sql; 
	select count(*) as n_miss_inj 
	from starting_pop 
	where (w5_py_assault_inj=. or w5_py_serious_injury=. or w5_py_suicide_attempt=.); 
	quit;
run; *expect to flag an additional 499; 

data flag_miss_outcomes; 
	set starting_pop; 
	if (w5_py_assault_inj=. or w5_py_serious_injury=. or w5_py_suicide_attempt=.) then in_analytic=0; *note the 'or' - exclude if missing on any.; 
	else in_analytic=1; 
;
run; *n=12,057; 

	/* In parallel - repeat for expanded version of dataset for sib analysis. */
	data flag_miss_outcomes_sib; 
		set starting_pop_sib; 
		if (w5_py_assault_inj=. or w5_py_serious_injury=. or w5_py_suicide_attempt=.) then in_analytic=0; *note the 'or' - excluded if missing on any.; 
		else in_analytic=1; 
	;
	run; *n=12,300;

/* STEP THREE. Flag those missing on ANY of the adolescent MH predictors or covariates. */

/* Bring in covariate/predictor info */ 
proc contents data=AHdata.covariates_predictors_final; run; *n=20,745 (is not restricted to those with W5 data); 

/* Left join keeps all rows from flag_miss_outcomes, adds in covariate columns */ 
proc sql; 
	create table join_covar_pred as 
	select * from flag_miss_outcomes o 
	left join AHdata.covariates_predictors_final p 
	on o.aid=p.aid; 
	quit;
run; * n = 12,057 ; 

	/* In parallel - repeat with the expanded version for sib analysis */
	proc sql; 
		create table join_covar_pred_sib as 
		select * from flag_miss_outcomes_sib o 
		left join AHdata.covariates_predictors_final p
		on o.aid=p.aid; 
		quit;
	run; * n = 12,300 ; 

/* First, flag those w/ missing adolesc. MH */

/* How many new people do we expect to flag? */ 
proc freq data=join_covar_pred; 
	table any_adol_mh ext_adol_mh int_adol_mh /missing; 
	where in_analytic=1; 
run; *48; 

data flag_miss_mh_pred; 
	set join_covar_pred; 
	*recode in_analytic to 0 if ANY of the MH indicators are missing. Should move 48 people from in_analytic=1 to 0; 
	if (any_adol_mh=. or ext_adol_mh=. or int_adol_mh=.) then in_analytic=0; 
run; *n=12,057; 

	/* In parallel: Again for expanded dataset for sib analyses. */
	data flag_miss_mh_pred_sib; 
		set join_covar_pred_sib;
		if (any_adol_mh=. or ext_adol_mh=. or int_adol_mh=.) then in_analytic=0; 
	run; *n=12,300; 

/* Second, flag those missing on covariates. */ 

 /* How many do we expect to flag? */ 
proc means data=flag_miss_mh_pred n nmiss min max mean std; 
	var w1_sex w1_race2 w1_ethnicity w5_age w1_ses w1_cog_ability ; 
	where in_analytic=1; 
run;  

proc sql; 
	select count(*) as N_missing_any_cov from flag_miss_mh_pred
	where (w1_sex=. or w1_race2=. or w1_ethnicity=. or w5_age=. or w1_ses=. or w1_cog_ability=.) and in_analytic=1; 
	quit; 
run; *1,147;

 /* Now flagging these rows */ 
data flag_miss_covars; 
	set flag_miss_mh_pred; 
	*recode in_analytic to 0 if ANY of the covariates are missing; 
	if (w1_sex=. or w1_race2=. or w1_ethnicity=. or w5_age=. or w1_ses=. or w1_cog_ability=.) then in_analytic=0; 
run; *n=12,057; 

	/* Again in expanded dataset for sib analyses */
	data flag_miss_covars_sib; 
		set flag_miss_mh_pred_sib; 
		if (w1_sex=. or w1_race2=. or w1_ethnicity=. or w5_age=. or w1_ses=. or w1_cog_ability=.) then in_analytic=0; 
	run;

/* OUTPUTTING STEP-BY-STEP CHANGING N.
	See Figure S1. */ 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\startingpop_to_analyticsample.xlsx"
		  options(sheet_interval='NONE'); 

ods text="N of all AH participants at Wave V"; 
proc sql; 
	select count(*) as N_participants from all_w5;  
	quit; * 12,300; 
 
ods text="N with non-missing Wave V cross-sectional design vars"; 
proc sql; 
	select count(*) as N_nonmiss_designvars from all_w5
	where missing_design_vars=0; 
	quit; * 12,057; 

ods text="Lose 499 b/c missing inj. outcomes. New N after dropping them is..."; 
proc sql; 
	select count(*) as N_nonmiss_outcomes from flag_miss_outcomes
	where in_analytic=1; 
	quit; * 11,558; 

ods text="Lose 48 b/c missing on either int. or ext. adolescent MH indicator. New N after dropping them is..."; 
proc sql; 
	select count(*) as N_nonmiss_int_ext_mh from flag_miss_mh_pred 
	where in_analytic=1; 
	quit; * 11,510; 

ods text="Lose 1,147 b/c missing on any of: sex, race, ethnicity, age, SES, or cognitive ability. New N after dropping them is..."; 
proc sql; 
	select count(*) as N_nonmiss_covars from flag_miss_covars
	where in_analytic=1; 
	quit; * 10,363; 

ods text="So analytic sample for aims 1-3a is 10,363 / 12,300 = 84% of starting pop";  

ods excel close; 

proc contents data=flag_miss_covars; run; 

/* FINAL STEPS BEFORE GENERATING ANALYTIC FILE. 

   (A) coding just a couple vars that will be of interest for initial descriptive stats,
   from the already-coded outcome vars.

   (B) Creating analytic_wt variable, needed for running properly weighted analyses given 
   subpopulation (see documentation:
	https://addhealth.cpc.unc.edu/wp-content/uploads/docs/events/AH_Guidelines_2014_Users_Conference_Chen.pdf) 

   (C) Renaming w1_ethnicity for clarity 

   (D) Creating subpopulation indicators for Aim 4 (which will need to drop people with nonmissing Aim 4 'circumstances' outcomes 
       and for the secondary analyses for the alternate outcomes (lenient assault injury, conservative 
       suicide attempt injury, binary high-frequency falls). These will be more restricted versions of the overall study sample. 

   (E) Create a re-coded indicator of amount debt following this scheme: 
		0    --> 0 (None) 
        1-2  --> 1 (Up to $24,999)
        3-8  --> 2 ($25,000+) 
		.    --> . (Missing) 	

	(F) To save confusion later, drop w1_race1 and rename w1_race2 to w1_race. 
		We won't be using w1_race1 in this project. 
*/

data flag_miss_covars2; 
	set flag_miss_covars (drop=missing_design_vars w1_race1); 
	* (A); 
	if (w5_py_assault_inj = 1 or w5_py_suicide_attempt=1 or w5_py_serious_injury=1)
		then w5_any_inj_type=1; 
    else if (w5_py_assault_inj=. or w5_py_suicide_attempt=. or w5_py_serious_injury=.)
		then w5_any_inj_type=.; 
	else w5_any_inj_type=0; 

	if (w5_py_assault_inj = 1 or w5_py_serious_injury=1) 
		then w5_assault_or_accid_inj=1; 
	else if (w5_py_assault_inj=. or w5_py_serious_injury=.) 
		then w5_assault_or_accid_inj=.; 
		else w5_assault_or_accid_inj=0; 

	* (B); 
	analytic_wt=gsw5; *create new var, analytic_wt, with same values as weights from AH; 
	if in_analytic=0 then analytic_wt=0.00001; *if individual isn't in analytic sample, 
											    re-set their weights to near-zero; 

	* (C); 
	rename w1_ethnicity = w1_hispanic_ethnicity; 

	* (D); 
	if in_analytic=1 and w5_amount_debt ne . and w5_fair_poor_health ne . and w5_lacks_support ne . 
	   and w5_uninsured ne . and w5_unmet_hc_need ne . 
	   then in_aim4_subpop=1; 
	   	else in_aim4_subpop=0;

	if in_analytic=1 and w5_unemployed ne . and w5_amount_debt ne . and w5_fair_poor_health ne . and w5_lacks_support ne . 
	   and w5_uninsured ne . and w5_unmet_hc_need ne . then in_aim4_unempl_subpop=1; 
	    else in_aim4_unempl_subpop=0;  
 
	if in_analytic=1 and w5_alt_lenient_assault_inj ne . then in_sec_assault_subpop=1; 
		else in_sec_assault_subpop=0; 

	if in_analytic=1 and w5_alt_sui_attempt_inj ne . then in_sec_suicide_subpop=1; 
		else in_sec_suicide_subpop=0; 

	if in_analytic=1 and w5_bin_hf_falls ne . then in_sec_hffalls_subpop=1; 
		else in_sec_hffalls_subpop=0; 

	* (E); 
	if w5_amount_debt = . then w5_recode_debt = .; 
		else if w5_amount_debt = 0 then w5_recode_debt =0; 
		else if w5_amount_debt in(1,2) then w5_recode_debt=1; 
		else if w5_amount_debt in (3,4,5,6,7,8) then w5_recode_debt=2; 
		label w5_recode_debt = '0=None, 1=Up to $24,999, 2=$25,000+'; 

	* (F) ; 
	rename w1_race2 = w1_race; 

run; *n=12,057; 

** check Ns; 
proc freq data=flag_miss_covars2; 
	table in_analytic*in_aim4_subpop in_analytic*in_aim4_unempl_subpop in_aim4_subpop*in_aim4_unempl_subpop;
run;

** check re-code of debt variable ; 
proc freq data=flag_miss_covars2; table w5_amount_debt*w5_recode_debt; format w5_amount_debt debt.; run; 

	/* Repeat final steps for the expanded version of analytic file just for sib analyses. */
	data flag_miss_covars2_sib; 
		set flag_miss_covars_sib (drop=missing_design_vars w1_race1); 
		* (A); 
		if (w5_py_assault_inj = 1 or w5_py_suicide_attempt=1 or w5_py_serious_injury=1)
			then w5_any_inj_type=1; 
	    else if (w5_py_assault_inj=. or w5_py_suicide_attempt=. or w5_py_serious_injury=.)
			then w5_any_inj_type=.; 
		else w5_any_inj_type=0; 

		if (w5_py_assault_inj = 1 or w5_py_serious_injury=1) 
			then w5_assault_or_accid_inj=1; 
		else if (w5_py_assault_inj=. or w5_py_serious_injury=.) 
			then w5_assault_or_accid_inj=.; 
			else w5_assault_or_accid_inj=0; 

		* (C); 
		rename w1_ethnicity = w1_hispanic_ethnicity; 

		* (F) ; 
		rename w1_race2 = w1_race; 

	run; *n=12,300; 

** For the unemployment variable, how many dropped are true missing vs. excluded because they 
are not in the labor force? See Figure S1. ; 
proc freq data=flag_miss_covars2; 
	table qa_unempl_miss*(in_aim4_subpop in_aim4_unempl_subpop) 
		  in_aim4_subpop*in_aim4_unempl_subpop /missing; 
run; 

/* OUTPUTTING FILE W/ ANALYTIC SAMPLE & STUDY VARS */ 
libname AHdata "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Intermediate_Data" ; 

proc contents data=flag_miss_covars2; run; 
proc sort data=flag_miss_covars2; by aid; run;
proc sort data=flag_miss_covars2 nodupkey out=dup_check; by aid; run; /*no duplicate aid's*/ 

data AHdata.analytic; 
	set flag_miss_covars2;
run; 

	/* In parallel - also output expanded datset for sib analyses */
	proc sort data=flag_miss_covars2_sib; by aid; run; 
	proc sort data=flag_miss_covars2_sib nodupkey out=dup_check2; by aid; run; 

	data AHdata.expanded_analytic_forsibs; 
		set flag_miss_covars2_sib;
	run; 
