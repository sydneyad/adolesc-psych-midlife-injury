
**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Fully adjusted models assessing ANY, INT, EXT psychopathology --> Injury
* AUTHOR: Sydney M. Adams
* INPUT FILE(S):  analytic.sas7bdat (must run SAS code files 1-5 before running this!) 
* OUTPUT FILE(S): aim3a_adj_model_results.xlsx
* RELEVANT RESULTS IN MANUSCRIPT: Table 2 (Adjusted OR estimates) 
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

** Recall, N=12,057 individuals with non-missing w5 design vars. "in_analytic" indicates if they are in our analytic sample.; 
proc contents data=AHdata.analytic; run; 

** Create temp version of file to interact with ; 
data analytic; set AHdata.analytic; run; 

** Examine covariate descriptives by psychopathology/injury status; 

%macro surveydescriptives_bygroup(indata=, bygroup=, var=); 

proc corr data=&indata; 
	var &bygroup &var; 
run; 

proc surveymeans data=&indata nobs nmiss q1 median q3 min max mean std missing; 
	var &var; 
	cluster psuscid; 
	strata region; 
	weight gsw5; 
	domain in_analytic*&bygroup; 
run; 

%mend; 

%surveydescriptives_bygroup(indata=analytic, bygroup=any_adol_mh, var=w1_ses w1_cog_ability); 
%surveydescriptives_bygroup(indata=analytic, bygroup=int_adol_mh, var=w1_ses w1_cog_ability); 
%surveydescriptives_bygroup(indata=analytic, bygroup=ext_adol_mh, var=w1_ses w1_cog_ability); 

%surveydescriptives_bygroup(indata=analytic, bygroup=w5_py_suicide_attempt, var=w1_ses w1_cog_ability); 
%surveydescriptives_bygroup(indata=analytic, bygroup=w5_py_assault_inj, var=w1_ses w1_cog_ability); 
%surveydescriptives_bygroup(indata=analytic, bygroup=w5_py_serious_injury, var=w1_ses w1_cog_ability); 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\aim3a_adj_model_results.xlsx"
	  options(sheet_interval='NONE');

** RUNNING ADJUSTED MODELS (See Table 2); 
  * adjusted for demographics (sex, race, ethnicity, and wave V age), SES, and cognitive ability ;
  * note for race & sex - White and male are defaulting to ref b/c of how values are ordered (1=W, 1=M) ; 

%macro run_adjusted_log_reg(data=, mh_pred=, outcome=); 

proc surveylogistic data=&data missing; 
		cluster psuscid; 
		strata region; 
		weight analytic_wt; 
		class w1_race w1_sex w1_hispanic_ethnicity / param=ref;
		model &outcome (event='1') = w1_sex w1_race w1_hispanic_ethnicity w5_age w1_ses w1_cog_ability &mh_pred; 
		format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 

%mend; 

%run_adjusted_log_reg(data=analytic, outcome=w5_py_suicide_attempt, mh_pred=any_adol_mh); 
%run_adjusted_log_reg(data=analytic, outcome=w5_py_assault_inj, mh_pred=any_adol_mh); 
%run_adjusted_log_reg(data=analytic, outcome=w5_py_serious_injury, mh_pred=any_adol_mh); 

%run_adjusted_log_reg(data=analytic, outcome=w5_py_suicide_attempt, mh_pred=int_adol_mh); 
%run_adjusted_log_reg(data=analytic, outcome=w5_py_assault_inj, mh_pred=int_adol_mh); 
%run_adjusted_log_reg(data=analytic, outcome=w5_py_serious_injury, mh_pred=int_adol_mh); 

%run_adjusted_log_reg(data=analytic, outcome=w5_py_suicide_attempt, mh_pred=ext_adol_mh); 
%run_adjusted_log_reg(data=analytic, outcome=w5_py_assault_inj, mh_pred=ext_adol_mh); 
%run_adjusted_log_reg(data=analytic, outcome=w5_py_serious_injury, mh_pred=ext_adol_mh); 

ods excel close; 
