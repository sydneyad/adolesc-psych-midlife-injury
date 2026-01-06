**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Descriptives and analyses for Aim 4 midlife circumstances outcomes  
* AUTHOR: Sydney M. Adams
* INPUT FILE(S):  analytic.sas7bdat (must run SAS code files 1-5 before running this!) 
* OUTPUT FILE(S): - aim4_descriptives.xlsx
*				  - aim4_baseline_models_bin.xlsx
*				  - aim4_baseline_models_multi.xlsx
*				  - aim4_adj_models_bin.xlsx
*				  - aim4_adj_models_multi.xlsx
* RELEVANT RESULTS IN MANUSCRIPT: 
*   Figure 2 (Forest plot of ORs) 
*   Table S5 (Tabled ORs) 
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

** NOTE the 'aim 4' midlife circumstance analyses have a different subpopulation given missingness on the outcome variables, 
and there is also a unique subpopulation for the unemployment analysis which excludes individuals not in the labor force at W5.
Use these below to create weights set to near-zero for those not in the respective subpops: ; 

data analytic_aim4; 
	set AHdata.analytic; 
	aim4_wt=gsw5; *first set to value of weights from AH; 
	if in_aim4_subpop=0 then aim4_wt=0.00001; *then if they're not in aim4 subpop, re-set their weights to near-zero; 

	aim4_unempl_wt=gsw5; 
	if in_aim4_unempl_subpop=0 then aim4_unempl_wt=0.00001; 
run; 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\aim4_descriptives.xlsx"
	  options(sheet_interval='NONE');

proc sql; 
	select count(*) as N_Aim4 from analytic_aim4
	where in_aim4_subpop=1; 
	quit; 

proc sql; 
	select count(*) as N_Aim4 from analytic_aim4
	where in_aim4_unempl_subpop=1; 
	quit; 

** Weighted frequencies of outcomes across Aim 4 sample; 
proc surveyfreq data=analytic_aim4 missing; 
	table w5_recode_debt w5_fair_poor_health w5_lacks_support w5_uninsured w5_unmet_hc_need; 
	cluster psuscid; 
	strata region; 
	weight aim4_wt; 
	format w5_amount_debt debt.; 
run; 

proc surveyfreq data=analytic_aim4 missing; 
	table w5_unemployed; 
	cluster psuscid; 
	strata region; 
	weight aim4_unempl_wt; 
run; 

** Weighted frequencies of outcomes cross-tabbed with any adolescent MH predictor.;
proc surveyfreq data=analytic_aim4 missing; 
	table (any_adol_mh int_adol_mh ext_adol_mh)*(w5_recode_debt w5_fair_poor_health w5_lacks_support w5_uninsured w5_unmet_hc_need) /row;  
	cluster psuscid; 
	strata region; 
	weight aim4_wt; 
	format w5_amount_debt debt.; 
run; 

proc surveyfreq data=analytic_aim4 missing; 
	table (any_adol_mh int_adol_mh ext_adol_mh)*w5_unemployed; 
	cluster psuscid; 
	strata region;
	weight aim4_unempl_wt; 
run; 

ods excel close; 

** Demographic-Adjusted Models for Aim 4 Outcomes ; 

%macro run_demogr_adj_log_reg_aim4(data=, mh_pred=, outcome=); 

/* recall need to use diff subpop for unemployed analysis */ 
%if &outcome ^= w5_unemployed %then %do; 

proc surveylogistic data=&data missing; 
		cluster psuscid; 
		strata region; 
		weight aim4_wt; 
		class w1_race w1_sex w1_hispanic_ethnicity / param=ref;
		model &outcome (event='1') = w1_sex w1_race w1_hispanic_ethnicity w5_age &mh_pred; 
		format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 

%end;

%else %do; 

proc surveylogistic data=&data missing; 
		cluster psuscid; 
		strata region; 
		weight aim4_unempl_wt; 
		class w1_race w1_sex w1_hispanic_ethnicity / param=ref;
		model &outcome (event='1') = w1_sex w1_race w1_hispanic_ethnicity w5_age &mh_pred; 
		format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 
%end; 

%mend; 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\aim4_baseline_models_bin.xlsx"
	  options(sheet_interval='NONE');

%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_fair_poor_health, mh_pred=any_adol_mh); 
%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_fair_poor_health, mh_pred=int_adol_mh); 
%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_fair_poor_health, mh_pred=ext_adol_mh); 

%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_lacks_support, mh_pred=any_adol_mh); 
%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_lacks_support, mh_pred=int_adol_mh); 
%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_lacks_support, mh_pred=ext_adol_mh); 

%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_unemployed, mh_pred=any_adol_mh); 
%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_unemployed, mh_pred=int_adol_mh); 
%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_unemployed, mh_pred=ext_adol_mh); 

%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_uninsured, mh_pred=any_adol_mh); 
%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_uninsured, mh_pred=int_adol_mh); 
%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_uninsured, mh_pred=ext_adol_mh); 

%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_unmet_hc_need, mh_pred=any_adol_mh); 
%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_unmet_hc_need, mh_pred=int_adol_mh); 
%run_demogr_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_unmet_hc_need, mh_pred=ext_adol_mh); 

ods excel close; 

** using multinomial logistic regression to study debt outcome, which has 3 levels ; 

%macro run_demogr_adj_debt_model(data=, mh_pred=); 

proc surveylogistic data=&data missing; 
	class w1_race w1_sex w1_hispanic_ethnicity w5_recode_debt (ref='0') / param=ref;
	cluster psuscid; 
	strata region; 
	weight aim4_wt; 
	model w5_recode_debt = w1_sex w1_race w1_hispanic_ethnicity w5_age &mh_pred / link=glogit; 
	format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 

%mend;

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\aim4_baseline_models_multi.xlsx"
	  options(sheet_interval='NONE');

%run_demogr_adj_debt_model(data=analytic_aim4, mh_pred=any_adol_mh); 
%run_demogr_adj_debt_model(data=analytic_aim4, mh_pred=int_adol_mh); 
%run_demogr_adj_debt_model(data=analytic_aim4, mh_pred=ext_adol_mh); 

ods excel close; 

** Secondary adjusted (SES + Cog Ability) Models for Aim 4 Outcomes ; 

%macro run_adj_log_reg_aim4(data=, mh_pred=, outcome=); 

%if &outcome ^= w5_unemployed %then %do; 
proc surveylogistic data=&data missing; 
		cluster psuscid; 
		strata region; 
		weight aim4_wt; 
		class w1_race w1_sex w1_hispanic_ethnicity / param=ref;
		model &outcome (event='1') = w1_sex w1_race w1_hispanic_ethnicity w5_age &mh_pred w1_ses w1_cog_ability; 
		format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 
%end; 

%else %do; 
proc surveylogistic data=&data missing; 
		cluster psuscid; 
		strata region; 
		weight aim4_unempl_wt; 
		class w1_race w1_sex w1_hispanic_ethnicity / param=ref;
		model &outcome (event='1') = w1_sex w1_race w1_hispanic_ethnicity w5_age &mh_pred w1_ses w1_cog_ability; 
		format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 
%end;

%mend; 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\aim4_adj_models_bin.xlsx"
	  options(sheet_interval='NONE');

%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_fair_poor_health, mh_pred=any_adol_mh); 
%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_fair_poor_health, mh_pred=int_adol_mh); 
%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_fair_poor_health, mh_pred=ext_adol_mh); 

%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_lacks_support, mh_pred=any_adol_mh); 
%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_lacks_support, mh_pred=int_adol_mh); 
%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_lacks_support, mh_pred=ext_adol_mh); 

%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_unemployed, mh_pred=any_adol_mh); 
%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_unemployed, mh_pred=int_adol_mh); 
%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_unemployed, mh_pred=ext_adol_mh); 

%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_uninsured, mh_pred=any_adol_mh); 
%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_uninsured, mh_pred=int_adol_mh); 
%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_uninsured, mh_pred=ext_adol_mh); 

%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_unmet_hc_need, mh_pred=any_adol_mh); 
%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_unmet_hc_need, mh_pred=int_adol_mh); 
%run_adj_log_reg_aim4(data=analytic_aim4, outcome=w5_unmet_hc_need, mh_pred=ext_adol_mh); 

ods excel close; 

%macro run_adj_debt_model(data=, mh_pred=); 

proc surveylogistic data=&data missing; 
	class w1_race w1_sex w1_hispanic_ethnicity w5_recode_debt (ref='0') / param=ref;
	cluster psuscid; 
	strata region; 
	weight aim4_wt; 
	model w5_recode_debt = w1_sex w1_race w1_hispanic_ethnicity w5_age &mh_pred w1_ses w1_cog_ability / link=glogit; 
	format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 

%mend;

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\aim4_adj_models_multi.xlsx"
	  options(sheet_interval='NONE');

%run_adj_debt_model(data=analytic_aim4, mh_pred=any_adol_mh); 
%run_adj_debt_model(data=analytic_aim4, mh_pred=int_adol_mh); 
%run_adj_debt_model(data=analytic_aim4, mh_pred=ext_adol_mh); 

ods excel close; 
