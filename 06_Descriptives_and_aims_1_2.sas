**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Gathering initial descriptive statistics in the analytic file, as well as demographic-adjusted
*				   models assessing ANY and INT/EXT psychopathology --> Injury
* AUTHOR: Sydney M. Adams
* LAST UPDATED: 1/5/2026 
* INPUT FILE(S):  analytic.sas7bdat (must run SAS code files 1-5 before running this!) 			
* OUTPUT FILE(S): Initial_descriptives.xlsx, aim1_results.xlsx, aim2_results.xlsx
* RELEVANT RESULTS IN MANUSCRIPT: 
* 	Table 1 (Sample characteristics)
*	Figure 1 (Displays prevalence of midlife injury by psychopathology status)
*   Table 2 (Baseline, demographic-adjusted OR estimates) 
*
**************************************************************************************************************;

libname AHdata "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Intermediate_Data"  ; 

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

** Recall, there are n=12,057 individuals with non-missing w5 design vars. "in_analytic" indicates if they are in our analytic sample.; 
proc contents data=AHdata.analytic; run; 
data analytic; set AHdata.analytic; run; 

/* DOUBLE CHECK STRATA / CLUSTER VARS  */ 
proc sql; 
	select count(distinct region) as distinct_regions, 
	       count(distinct psuscid) as distinct_strata 
	from analytic; 
	quit; 
run;  *4 regions, 132 strata; 

**********************; 
**** DESCRIPITVES ****; 
**********************; 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\Initial_descriptives.xlsx"
		  options(sheet_interval='NONE'); 

/* SAMPLE-WIDE WEIGHTED DESCRIPTIVES (see Table 1) */ 

ods text="Weighted descriptive stats for primary analytic sample, N=10,363"; 
proc surveymeans data=analytic nobs nmiss q1 median q3 min max mean std missing;  
	var w1_ses w1_cog_ability w5_age; 
	cluster psuscid; 
	strata region; 
	weight gsw5; 
	domain in_analytic; 
run; 

proc surveyfreq data=analytic missing; 
	table any_adol_mh ext_adol_mh int_adol_mh
		  w1_sex w1_race w1_hispanic_ethnicity
		  w5_py: w5_assault_or_accid_inj w5_any_inj_type; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run; 

title "Weighted injury crosstabs by type"; **see Results, Sample Characteristics text;  
proc surveyfreq data=analytic missing; 
	table w5_py_suicide_attempt*w5_py_serious_injury
	      w5_py_assault_inj*w5_py_serious_injury /row; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run; 
title; 
ods excel close; 

***************; 
**** AIM 1 ****; 
***************; 

/* UNADJ. (WEIGHTED) CROSS-TAB OF ANY MH BY INJURY OUTCOMES (See Figure 1) */

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\aim1_results.xlsx"
	  options(sheet_interval='NONE'); 

proc surveyfreq data=analytic missing; 
	table any_adol_mh*(w5_any_inj_type w5_py_suicide_attempt w5_assault_or_accid_inj w5_py_assault_inj w5_py_serious_injury) /row; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run; 

/* DEMOGR-ADJUSTED ANY ADOL PSYCH --> INJURY (See Table 2) */ 

%macro run_demogr_adj_log_reg(data=, mh_pred=, outcome=); 

proc surveylogistic data=&data missing; 
		cluster psuscid; 
		strata region; 
		weight analytic_wt; 
		class w1_race w1_sex w1_hispanic_ethnicity / param=ref;
		model &outcome (event='1') = w1_sex w1_race w1_hispanic_ethnicity w5_age &mh_pred; 
		format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 

%mend; 

%run_demogr_adj_log_reg(data=analytic, outcome=w5_py_suicide_attempt, mh_pred=any_adol_mh); 
%run_demogr_adj_log_reg(data=analytic, outcome=w5_py_assault_inj, mh_pred=any_adol_mh); 
%run_demogr_adj_log_reg(data=analytic, outcome=w5_py_serious_injury, mh_pred=any_adol_mh); 

ods excel close; 

***************; 
**** AIM 2 ****; 
***************; 

/* UNADJ. CROSS-TAB OF INT/EXT MH BY INJURY OUTCOMES (See Figure 1) */

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\aim2_results.xlsx"
	  options(sheet_interval='NONE'); 

proc surveyfreq data=analytic missing; 
	table (int_adol_mh ext_adol_mh)*(w5_any_inj_type w5_py_suicide_attempt w5_assault_or_accid_inj w5_py_assault_inj w5_py_serious_injury) /row; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run; 


/* DEMOGR-ADJUSTED LOG. REGR. OF INT/EXT MH > INJURY (See Table 2) */

*int; 
%run_demogr_adj_log_reg(data=analytic, outcome=w5_py_suicide_attempt, mh_pred=int_adol_mh); 
%run_demogr_adj_log_reg(data=analytic, outcome=w5_py_assault_inj, mh_pred=int_adol_mh); 
%run_demogr_adj_log_reg(data=analytic, outcome=w5_py_serious_injury, mh_pred=int_adol_mh); 

*ext; 
%run_demogr_adj_log_reg(data=analytic, outcome=w5_py_suicide_attempt, mh_pred=ext_adol_mh); 
%run_demogr_adj_log_reg(data=analytic, outcome=w5_py_assault_inj, mh_pred=ext_adol_mh); 
%run_demogr_adj_log_reg(data=analytic, outcome=w5_py_serious_injury, mh_pred=ext_adol_mh); 

ods excel close; 


