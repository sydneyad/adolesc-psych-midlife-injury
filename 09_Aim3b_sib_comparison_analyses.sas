**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Descriptives, cross-tabs, sample-wide analyses, and sibling-comparison analyses in sibling sample
* AUTHOR: Sydney M. Adams
* INPUT FILE(S): sibling_analytic.sas (must run SAS files 1-8 before this!!) 
* OUTPUT FILE(S): sib_output.xlsx
*				  sib_pair_type_checks.xlsx 
* RELEVANT RESULTS IN MANUSCRIPT: 
*  Sample-wide and sibling-comparison analyses are reported in the text (Results) 
*  Test of sibling-comparison excluding unrelated siblings is reported in Table S5, Sensitivity Tests 
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
run;

data sib_analytic; 
	set AHdata.sibling_analytic;
run;

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\sib_output.xlsx"
	  options(sheet_interval='NONE');

proc contents data=sib_analytic; run; 

proc sql; 
	select count(distinct aid) as distinct_aid, count(distinct famid) as distinct_famid
    from sib_analytic;
quit; 

** Read-in analytic sample for ref; 
data in_analytic_full; 
	set AHdata.analytic (where=(in_analytic=1)); 
run; 

*** Cross-tabs of MH & Unintentional Injury ; 
proc freq data=sib_analytic; 
	table any_adol_mh*w5_py_serious_injury / missing ; 
run; 
proc freq data=in_analytic_full; 
	table any_adol_mh*w5_py_serious_injury / missing ; 
run; 
*** Note difference in pattern observed in sibling sub-sample vs. full analytic sample; 

*** Initial sample-wide / "population"-wide survey logistic models (not sib comparisons); 
** demogr-adjusted ; 
proc surveylogistic data=sib_analytic; 
	cluster famid; 
	class w1_race w1_sex w1_hispanic_ethnicity / param=ref; 
	model w5_py_serious_injury (event='1') = w1_sex w1_race w1_hispanic_ethnicity w5_age any_adol_mh; 
	format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 

** add cognitive ability ; 
proc surveylogistic data=sib_analytic; 
	cluster famid; 
	class w1_race w1_sex w1_hispanic_ethnicity / param=ref; 
	model w5_py_serious_injury (event='1') = w1_sex w1_race w1_hispanic_ethnicity w5_age any_adol_mh w1_cog_ability; 
	format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 

** add SES ; 
proc surveylogistic data=sib_analytic;  
	cluster famid; 
	class w1_race w1_sex w1_hispanic_ethnicity / param=ref; 
	model w5_py_serious_injury (event='1') = w1_sex w1_race w1_hispanic_ethnicity w5_age any_adol_mh w1_cog_ability w1_ses; 
	format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 

*** Investigating within-family discordance on exposures/outcome; 
**  Ultimately, only families with variability on any psychopathology + unintentional injury will
    inform the sibling-comparison estimates. ;

**  The following code groups the data by family ID and then looks across rows for certain things... ; 
**  By asking SQL if the maximum value of MH within a family is >0, we can ask, did any sib in the 
    family have a mental health condition? And by asking if the variance of MH within a family is >0, 
    we can ask, was there at least some variability in mental health status within the family? ; 

proc sql; 
	create table check_discordance as select *, /* selecting all vars has SQL keep 1 row per participant */ 

	/* flag any MH, any injury, any both within family */ 
	max(any_adol_mh)>0 as mh_in_fam, max(w5_py_serious_injury)>0 as injury_in_fam, 
	(max(any_adol_mh)>0 and max(w5_py_serious_injury)>0) as mh_and_inj_in_fam, 

	/* flag variance on individual predictors, outcome in family */ 
	var(any_adol_mh)>0 as var_any_mh, var(w5_py_serious_injury)>0 as var_serious_inj,   
	var(w1_cog_ability)>0 as var_cog, var(w1_race)>0 as var_race, var(w1_ses)>0 as var_ses,  
    var(w1_hispanic_ethnicity)>0 as var_ethnicity, var(w5_age)>0 as var_age, var(w1_sex)>0 as var_sex, 

	/* flag variance on any predictor in family */ 
	((var(any_adol_mh)>0) or (var(w1_cog_ability)>0) or (var(w1_race)>0) or (var(w5_age)>0) 
	  or (var(w1_sex)>0) or (var(w1_hispanic_ethnicity)>0) or (var(w1_ses)>0)) as var_any_predictor, 

	/* flag those who are discordant on main predictor and outcome - that will be the pairs that
	  inform the conditional logistic regression */ 
	(var(w5_py_serious_injury)>0 and var(any_adol_mh)>0) as var_inj_mh

	from sib_analytic 
	group by famid;
	quit;
run; 

* NOTE because I kept 1 row per participant but grouped by family, the resulting frequencies are of participants
  belonging to families/pairs with discordance on a given characteristic.; 
proc freq data=check_discordance; 
	table var: ; 
run; 
proc freq data=check_discordance;
	table var_any_mh*var_serious_inj;
run; 

* Among participants from families where SOMEONE had MH/Injury, how many varied?;  
proc freq data=check_discordance; 
	 table mh_in_fam*var_any_mh injury_in_fam*var_serious_inj mh_and_inj_in_fam*var_inj_mh
	       var_any_mh*var_serious_inj var_any_mh*var_inj_mh
	 / nopercent nocol;
run; 	

*** Print informative sibling comparison N ;  
proc sql; 
	select count(distinct aid) as sib_analytic_n_ptcpts, 
	count(distinct famid) as sib_analytic_n_families
	from check_discordance
	where var_inj_mh=1; 
quit;

*** Restrict the data set to those who will inform estimates ; 
data sib_informative; 
	set check_discordance ; 
	if var_inj_mh=1; 
	keep aid famid sib: n_pairs fam_member_count any_adol_mh w1_race w1_hispanic_ethnicity w1_sex w1_ses w1_cog_ability 
         w5_age w5_py_serious_injury var_inj_mh; 
run; *n=127; 

proc contents data=sib_informative; 

*** Re-run survey logistic in this even-further-restricted sample. Expect VERY LITTLE power. ; 
proc surveylogistic data=sib_informative missing; 
	cluster famid; 
	class w1_race w1_sex w1_hispanic_ethnicity / param=ref; 
	model w5_py_serious_injury (event='1') = w1_sex w1_race w1_hispanic_ethnicity w5_age any_adol_mh w1_cog_ability w1_ses; 
	format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 

***; 
*** Sibling comparisons ;
***; 
 
** First unadjusted ; 
proc logistic data=sib_informative; 
	model w5_py_serious_injury (event='1') = any_adol_mh; 
	strata famid; 
run; 

** Then adjusted, using macro ; 
%macro adj_sib_comparison(data=, class_vars=, covariates=); 

title "Siblng fixed-effects analysis in &data, adjusted for &covariates"; 
	%if &class_vars ne ' ' %then %do; 

	proc logistic data=&data; 
		class &class_vars / param=ref; 
		model w5_py_serious_injury (event='1') = any_adol_mh &covariates; 
		strata famid; 
	run; 
	%end; 

	%else %do; 
	proc logistic data=&data; 
		model w5_py_serious_injury (event='1') = any_adol_mh &covariates; 
		strata famid; 
	run; 
	%end; 
title; 

%mend; 

* add sex ; 
%adj_sib_comparison(data=sib_informative, class_vars=w1_sex, covariates=w1_sex); 

* add age ; 
%adj_sib_comparison(data=sib_informative, class_vars=w1_sex, covariates=w1_sex w5_age); 

* add race ; 
%adj_sib_comparison(data=sib_informative, class_vars=w1_sex w1_race, 
					covariates=w1_sex w5_age w1_race); 
					** note severe lack of precision, which makes sense; 

* add ethnicity ; 
%adj_sib_comparison(data=sib_informative, class_vars=w1_sex w1_race w1_hispanic_ethnicity, 
					covariates=w1_sex w5_age w1_race w1_hispanic_ethnicity); 

* add cognitive ability ; 
%adj_sib_comparison(data=sib_informative, class_vars=w1_sex w1_race w1_hispanic_ethnicity, 
					covariates=w1_sex w5_age w1_race w1_hispanic_ethnicity w1_cog_ability); 

* add SES ; 
%adj_sib_comparison(data=sib_informative, class_vars=w1_sex w1_race w1_hispanic_ethnicity, 
					covariates=w1_sex w5_age w1_race w1_hispanic_ethnicity w1_cog_ability w1_ses); 

ods excel close; 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\sib_pair_type_checks.xlsx"
	  options(sheet_interval='NONE');

*** Outputting informative sib sample to get descriptives for it, and other samples,
in 9b_Aim3b_sib_comparing... ; 

data AHdata.sib_informative; 
	set sib_informative; 
run; 


*******************; 
**** QA CHECKS ****; 
*******************; 

** Re-run dropping unrelated sib pairs; 
data sib_informative_dropun; 
	set sib_informative; 
	if (sib1="NR" or sib2="NR" or sib3="NR" or sib4="NR") then delete; 
run;  

** Check outcome rate for any_adol_mh to ensure does not violate min cell size; 
proc freq data=sib_informative_dropun; table any_adol_mh*w5_py_serious_injury; run; 

* Run models, unadjusted and adjusted; 
%adj_sib_comparison(data=sib_informative_dropun, class_vars=, covariates=);

** See Table S5, Sensitivity Tests; 
%adj_sib_comparison(data=sib_informative_dropun, class_vars=w1_sex w1_race, 
					covariates=w1_sex w5_age w1_race w1_hispanic_ethnicity w1_ses w1_cog_ability); 

** Check: What is the sample-wide association among all individuals in the sib subsample followed to Wave V 
(before dropping incomplete sibling groups)? ; 

data starting_full_w5; 
	set AHdata.expanded_analytic_forsibs; ** this is the analytic file of individuals at Wave V + study vars, 
										     WITHOUT dropping those with missing design variables ; 
run;

proc sql; 
	create table sibs_w5 as select * from AHdata.starting_sibs s /* this is the starting sib sample */ 
	inner join starting_full_w5 w5
	on s.aid=w5.aid;
quit; ** n = 3,190 ; 

proc contents data=sibs_w5; run; 

data sibs_w5_nonmissdata; 
	set sibs_w5;
	where w1_sex ne . and w1_race ne . and w5_py_serious_injury ne . and
			w1_hispanic_ethnicity ne . and w5_age ne . and 
			any_adol_mh ne . and w1_cog_ability ne . and w1_ses ne .; 
run; ** n = 2,808 ; 

proc surveylogistic data=sibs_w5_nonmissdata missing;  
	cluster famid; 
	class w1_race w1_sex w1_hispanic_ethnicity / param=ref; 
	model w5_py_serious_injury (event='1') = w1_sex w1_race w1_hispanic_ethnicity w5_age any_adol_mh w1_cog_ability w1_ses; 
	format w1_race racef. w1_sex sexf. w1_hispanic_ethnicity ethnicityf.; 
run; 

