
**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Running secondary/sensitivity analyses, including: 
*                 (1) Re-run with alternate externalizing/any, allowing ADHD dx at age 4-18 
*                 (2) Re-run unintent. inj models excl. individuals who reported assault/suicide att.
*                 (3) Re-run with alternate (conservative) intent. self-inj def 
*                 (4) Re-run with alternate (leniant) assault inj def 
*                 (5) Run analysis predicting high-frequency falls at midlife 
*				  (6) Run analysis using just prospectively assessed MH conditions  
* AUTHOR: Sydney M. Adams
* INPUT FILE(S):  AHdata.analytic
* OUTPUT FILE(S): sens_alt_cons_suicide.xlsx
*				  sens_altadhd.xlsx
*			      sens_altcohort_nosui_noassau.xlsx
*				  sens_alt_len_assault.xlsx
* RELEVANT RESULTS IN MANUSCRIPT: Table S5, Sensitivity Tests 
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

proc contents data=AHdata.analytic; run; 
data analytic; set AHdata.analytic; run; 

*** (1) Re-run with alternate externalizing/any, allowing ADHD dx at age 4-18 ;

proc freq data=analytic (where=(in_analytic=1)); 
	table alt_any_adol_mh_adhd * any_adol_mh alt_ext_adol_mh_adhd * ext_adol_mh 
          int_adol_mh w5_py: ; 
run; 

*Cross-tabs; 
proc surveyfreq data=analytic missing; 
	table (any_adol_mh alt_any_adol_mh_adhd)*(w5_py_suicide_attempt w5_py_assault_inj w5_py_serious_injury) /row; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run; 

proc surveyfreq data=analytic missing; 
	table (ext_adol_mh alt_ext_adol_mh_adhd)*(w5_py_suicide_attempt w5_py_assault_inj w5_py_serious_injury) /row; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run; 

*Log reg models; 
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

** First main analysis for ref; 

%run_adjusted_log_reg(data=analytic, mh_pred=any_adol_mh, outcome=w5_py_suicide_attempt); 
%run_adjusted_log_reg(data=analytic, mh_pred=any_adol_mh, outcome=w5_py_assault_inj); 
%run_adjusted_log_reg(data=analytic, mh_pred=any_adol_mh, outcome=w5_py_serious_injury); 

%run_adjusted_log_reg(data=analytic, mh_pred=ext_adol_mh, outcome=w5_py_suicide_attempt); 
%run_adjusted_log_reg(data=analytic, mh_pred=ext_adol_mh, outcome=w5_py_assault_inj);
%run_adjusted_log_reg(data=analytic, mh_pred=ext_adol_mh, outcome=w5_py_serious_injury); 

%run_adjusted_log_reg(data=analytic, mh_pred=int_adol_mh, outcome=w5_py_suicide_attempt); 
%run_adjusted_log_reg(data=analytic, mh_pred=int_adol_mh, outcome=w5_py_assault_inj); 
%run_adjusted_log_reg(data=analytic, mh_pred=int_adol_mh, outcome=w5_py_serious_injury); 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\sens_altadhd.xlsx"
	  options(sheet_interval='NONE');

proc surveyfreq data=analytic missing; 
	table (alt_any_adol_mh_adhd alt_ext_adol_mh_adhd)*(w5_py_suicide_attempt w5_py_assault_inj w5_py_serious_injury) /row; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run; 

** See Table S5; 

* alt any ; 
%run_adjusted_log_reg(data=analytic, mh_pred=alt_any_adol_mh_adhd, outcome=w5_py_suicide_attempt); 
%run_adjusted_log_reg(data=analytic, mh_pred=alt_any_adol_mh_adhd, outcome=w5_py_assault_inj); 
%run_adjusted_log_reg(data=analytic, mh_pred=alt_any_adol_mh_adhd, outcome=w5_py_serious_injury); 

* alt ext ; 
%run_adjusted_log_reg(data=analytic, mh_pred=alt_ext_adol_mh_adhd, outcome=w5_py_suicide_attempt);
%run_adjusted_log_reg(data=analytic, mh_pred=alt_ext_adol_mh_adhd, outcome=w5_py_assault_inj); 
%run_adjusted_log_reg(data=analytic, mh_pred=alt_ext_adol_mh_adhd, outcome=w5_py_serious_injury); 

ods excel close; 

*** (2) Re-run unintent. inj models excl. individuals who reported assault/suicide att. ;

** First prep - this analysis has its own subpop, needs its own weight variable.; 

proc freq data=analytic; 
	table in_analytic;
run; 

proc freq data=analytic (where=(in_analytic=1)); 
	table w5_py_suicide_attempt*w5_py_assault_inj ; 
run; 
 
data alt_analytic; 
	set analytic; 
	if (w5_py_suicide_attempt = 1 or w5_py_assault_inj = 1) then in_analytic=0; 
run; 

proc freq data=alt_analytic; 
	table in_analytic; 
run; 

data alt_analytic; 
	set alt_analytic; 
	if in_analytic=0 then analytic_wt=0.00001; 
run; 

** Look at frequency of injury, psychopathology in main analytic file vs. this one; 
proc freq data=analytic(where=(in_analytic=1)); 
	table w5_py_serious_injury w5_py_suicide_attempt w5_py_assault_inj any_adol_mh ; 
run; 
proc freq data=alt_analytic(where=(in_analytic=1)); 
	table w5_py_serious_injury w5_py_suicide_attempt w5_py_assault_inj any_adol_mh 
 	      int_adol_mh ext_adol_mh; 
run; 


ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\sens_altcohort_nosui_noassau.xlsx"
	  options(sheet_interval='NONE');

proc surveyfreq data=alt_analytic missing; 
	table (any_adol_mh int_adol_mh ext_adol_mh)*w5_py_serious_injury /row; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run; 

proc surveyfreq data=alt_analytic missing; 
	table any_adol_mh int_adol_mh ext_adol_mh w5_py_serious_injury; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run; 
 
** See Table S5; 
%run_adjusted_log_reg(data=alt_analytic, mh_pred=any_adol_mh, outcome=w5_py_serious_injury); 
%run_adjusted_log_reg(data=alt_analytic, mh_pred=int_adol_mh, outcome=w5_py_serious_injury); 
%run_adjusted_log_reg(data=alt_analytic, mh_pred=ext_adol_mh, outcome=w5_py_serious_injury); 

ods excel close; 

*** (3) Re-run with alternate (conservative) intent. self-inj def ;

** If there were differential missingness on the extra item used to create this alt def,
   there'd be a diff analytic sample (and diff analytic_wt var). but there's not, see below.; 
proc freq data=analytic; table in_analytic*in_sec_suicide_subpop; run; 

proc freq data=analytic; table w5_py_suicide_attempt*w5_alt_sui_attempt_inj; run; 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\sens_alt_cons_suicide.xlsx"
	  options(sheet_interval='NONE');

proc surveyfreq data=analytic missing; 
	table (any_adol_mh int_adol_mh ext_adol_mh)*w5_alt_sui_attempt_inj /row; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run; 


** See Table S5; 
%run_adjusted_log_reg(data=analytic, mh_pred=any_adol_mh, outcome=w5_alt_sui_attempt_inj);  
%run_adjusted_log_reg(data=analytic, mh_pred=int_adol_mh, outcome=w5_alt_sui_attempt_inj);
%run_adjusted_log_reg(data=analytic, mh_pred=ext_adol_mh, outcome=w5_alt_sui_attempt_inj); 

ods excel close; 

*** (4) Re-run with alternate (leniant) assault inj def ;

proc freq data=analytic; table in_analytic*in_sec_assault_subpop; run; 

proc freq data=analytic(where=(in_analytic=1)); 
	table w5_alt_lenient_assault_inj;
run; 

data alt_assault; 
	set analytic; 
	if in_sec_assault_subpop = 0 then analytic_wt=0.0001; 
run; 

proc freq data=alt_assault(where=(in_sec_assault_subpop=1)); 
	table any_adol_mh int_adol_mh ext_adol_mh w5_py_serious_injury 
	       w5_py_suicide_attempt w5_alt_lenient_assault_inj; 
run; 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\sens_alt_len_assault.xlsx"
	  options(sheet_interval='NONE');

proc surveyfreq data=alt_assault missing; 
	table (any_adol_mh int_adol_mh ext_adol_mh)*w5_alt_lenient_assault_inj /row; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run;


** See Table S5; 
%run_adjusted_log_reg(data=alt_assault, mh_pred=any_adol_mh, outcome=w5_alt_lenient_assault_inj);   
%run_adjusted_log_reg(data=alt_assault, mh_pred=int_adol_mh, outcome=w5_alt_lenient_assault_inj);  
%run_adjusted_log_reg(data=alt_assault, mh_pred=ext_adol_mh, outcome=w5_alt_lenient_assault_inj);

ods excel close; 

*** (5) Run analysis predicting high-frequency falls at midlife ;

proc freq data=analytic; table in_analytic*in_sec_hffalls_subpop; run; 
proc freq data=analytic(where=(in_analytic=1)); table w5_bin_hf_falls; run; 

data alt_falls; 
	set analytic; 
	if in_sec_hffalls_subpop=0 then analytic_wt=0.0001; 
run; 

proc freq data=alt_falls(where=(in_sec_hffalls_subpop=1)); 
	table any_adol_mh int_adol_mh ext_adol_mh w5_py_serious_injury 
	       w5_py_suicide_attempt w5_bin_hf_falls; 
run; 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\sec_hf_falls.xlsx"
	  options(sheet_interval='NONE');

proc surveyfreq data=alt_falls missing; 
	table w5_bin_hf_falls; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run;

proc surveyfreq data=alt_falls missing; 
	table (any_adol_mh int_adol_mh ext_adol_mh)*w5_bin_hf_falls /row; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run;

*run models - See Table S6; 
%run_adjusted_log_reg(data=alt_falls, mh_pred=any_adol_mh, outcome=w5_bin_hf_falls); 
%run_adjusted_log_reg(data=alt_falls, mh_pred=int_adol_mh, outcome=w5_bin_hf_falls);  
%run_adjusted_log_reg(data=alt_falls, mh_pred=ext_adol_mh, outcome=w5_bin_hf_falls);  

ods excel close; 

*** (6) Post-hoc retrospective reporting bias check
 	    Run int, ext, any --> unintentional injury using just prospectively assessed MH predictors

** Look at contents of analytic file again to point to these vars since they are not used in 
other analyses in this project.; 

proc contents data=AHdata.analytic; run; 

data analytic_prosp; 
	set AHdata.analytic; 
	** create indicator of any prospective mh; 
	if w1_w2_cesd_depression = 1 or w1_conduct_dis_prorated = 1 then prosp_adol_mh=1;
		else prosp_adol_mh=0; 
	** create subpop stmt ; 
	in_analytic_prosp=in_analytic; 
	if (w1_w2_cesd_depression =. or w1_conduct_dis_prorated =.) then in_analytic_prosp=0; 
	** create weight ; 
	analytic_prosp_wt = analytic_wt; 
	if in_analytic_prosp=0 then analytic_prosp_wt =0.00001; 
run;

proc freq data=analytic_prosp; table in_analytic_prosp; run; 
proc freq data=analytic_prosp; table in_analytic*in_analytic_prosp; run; 

** drop old in_analytic and wts and rename new ones, so that I can use my macro ; 
data analytic_prosp2; 
	set analytic_prosp (drop=in_analytic analytic_wt); ** drop in set stmt so it's as data is read in; 
	rename in_analytic_prosp=in_analytic; ** then rename ; 
	rename analytic_prosp_wt = analytic_wt; ** and rename ; 
run; 

** check combined var ; 
proc freq data=analytic_prosp2 (where=(in_analytic=1)); 
	table (w1_w2_cesd_depression w1_conduct_dis_prorated)*prosp_adol_mh / missing; 
run; 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\sens_prospective_mh.xlsx"
	  options(sheet_interval='NONE');

proc surveyfreq data=analytic_prosp2 missing; 
	table (prosp_adol_mh w1_w2_cesd_depression w1_conduct_dis_prorated)*w5_py_serious_injury /row; 
	cluster psuscid; 
	strata region; 
	weight analytic_wt; 
run;

** quick check; 
proc means data=analytic_prosp2 n nmiss; var w5_py_serious_injury; run; 

** run models - see Table S5; 
%run_adjusted_log_reg(data=analytic_prosp2, mh_pred=prosp_adol_mh, outcome=w5_py_serious_injury); 
%run_adjusted_log_reg(data=analytic_prosp2, mh_pred=w1_w2_cesd_depression, outcome=w5_py_serious_injury); 
%run_adjusted_log_reg(data=analytic_prosp2, mh_pred=w1_conduct_dis_prorated, outcome=w5_py_serious_injury); 

ods excel close; 

*** (7) - post-hoc test of continuous (not dichotomized) W1 prospective MH sx --> unintentional injury ; 

** check ns; 
proc means n nmiss min max mean median mode data=AHdata.analytic (where=(in_analytic=1)); var w1_cesd_sum_scaled w1_conduct_prorate; run; 

proc sql; 
	select count(*) 
	from AHdata.analytic
	where (in_analytic=1 and (w1_cesd_sum_scaled=. or w1_conduct_prorate=.));
quit; 

** NOTE as a very first step, I need to re-code the indicators to missing if w1 age is >= 19. this 
was already done for the dichotomous indicators, but it hasn't been done for the prospective symptom scores.; 

proc freq data=AHdata.analytic (where=(in_analytic=1)); 
	table w1_age /missing; 
	where w1_cesd_sum_scaled ^=. and w1_conduct_prorate ^=.;  
run; ** note there's some 19, 20, 21 y/os who will be re-coded to missing; 

data analytic_cont_prosp;
	set AHdata.analytic; 
	if w1_age >= 19 then do; 
		w1_cesd_sum_scaled=.; 
		w1_conduct_prorate=.; 
	end; 
run; 

** re-check ns; 
proc means n nmiss min max mean median mode data=analytic_cont_prosp (where=(in_analytic=1)); var w1_cesd_sum_scaled w1_conduct_prorate; run; 

proc sql; 
	select count(*) 
	from analytic_cont_prosp
	where (in_analytic=1 and (w1_cesd_sum_scaled=. or w1_conduct_prorate=.));
quit; 

proc freq data=analytic_cont_prosp (where=(in_analytic=1)); 
	table w1_age /missing; 
	where w1_cesd_sum_scaled ^=. and w1_conduct_prorate ^=.;  
run; 

data analytic_cont_prosp2; 
	set analytic_cont_prosp; 

	** revise subpop stmt ; 
	if (w1_cesd_sum_scaled =. or w1_conduct_prorate =.) then in_analytic=0; 

	** revise weight ; 
	if (w1_cesd_sum_scaled =. or w1_conduct_prorate =.) then analytic_wt =0.00001; 
run; 

proc means n nmiss min max mean median mode data=analytic_cont_prosp2 (where=(in_analytic=1)); var w1_cesd_sum_scaled w1_conduct_prorate; run; 

** revised subpop and weight vars look good.; 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\sens_cont_prospective_mh.xlsx"
	  options(sheet_interval='NONE');

** weighted mean adolesc mh symptoms, by midlife unintentional injury status; 
proc surveymeans data=analytic_cont_prosp2 nobs mean std median missing; 
	var w1_cesd_sum_scaled w1_conduct_prorate; 
	strata region;
	weight analytic_wt; 
	domain in_analytic*w5_py_serious_injury; 
run; 

** Run models - re-use macro, but note OR now represents the change in odds of injury associated with 
a one-unit change in CESD/conduct symptom scale.; 

** See Table S5; 
%run_adjusted_log_reg(data=analytic_cont_prosp2, mh_pred=w1_cesd_sum_scaled, outcome=w5_py_serious_injury);

%run_adjusted_log_reg(data=analytic_cont_prosp2, mh_pred=w1_conduct_prorate, outcome=w5_py_serious_injury);  

ods excel close; 
