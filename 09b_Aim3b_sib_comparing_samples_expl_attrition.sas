**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Comparing unweighted characteristics of starting vs. analytic main and sibling samples
* AUTHOR: Sydney M. Adams
* INPUT FILE(S): AHdata.covariates_predictors_final
*				 analytic_exp_sibs.sas7bdat (must run SAS code files 1-5 before running this!) 
*				 pairs.xpt from AH 
*		         AHdata.sibling_analytic.sas
* OUTPUT FILE(S): characterizing_samples.xlsx
* RELEVANT RESULTS IN MANUSCRIPT: Table S4, Unweighted characteristics of starting and analytic samples 				
*
************************************************************************************************************; 

libname AHdata "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Intermediate_Data"  ;

** Formats; 
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

** Macro for descriptives, to be re-used later. Note combining racial categories with low cell counts to avoid deductive disclosure risk.; 
%macro get_unweighted_descriptives(data=,injuries=); 

data &data; 
	set &data; 
	if w1_race in(3,4,5,6) then w1_race=5; 
run; 

title "unweighted, raw descriptives for sample in &data"; 
proc sql; 
	select count(distinct aid) as sample_n
	from &data;
quit;

proc freq data=&data; 
	table w1_sex w1_hispanic_ethnicity w1_race 
	any_adol_mh; 
run; 

proc means n min max mean stderr median p25 p75 data=&data; 
	var w1_cog_ability w1_ses; 
run; 

%if &injuries=1 %then %do; 

	proc freq data=&data; 
		table w5_py_serious_injury 
		      any_adol_mh*w5_py_serious_injury; 
	run; 

%end; 

%mend;  

** Identify the samples I want to run this on - 
	(1) Wave 1 full AH sample (N=20745) 
	(2) Wave V full AH sample (regardless of design variables, N=12300)
	(3) Full analytic study sample (N=10363)
    (4) Wave 1 full sibling subsample (N=5426) 
    (5) Wave V sibling subsample carried to W5 (N=3190) 
    (6) Wave V complete information/pairs sibling subsample (N=1796)
    (7) Informative/discordant sibling sample (N=127) 
; 

* (1); 
data starting_full_w1;
	set AHdata.covariates_predictors_final; ** this is the original predictors dataset - outcome stuff not included. 
											   and no one dropped ; 
	rename w1_race2 = w1_race; 
	rename w1_ethnicity = w1_hispanic_ethnicity; 
	** renaming above vars to match how things are coded in other files ; 
run; *20475; 

proc contents data=starting_full_w1; 
run; 

* (2);

data starting_full_w5; 
	set AHdata.expanded_analytic_forsibs; ** this is the analytic file of individuals at Wave V + study vars, 
										     WITHOUT dropping those with missing design variables ; 
run; *12300; 

* (3); 
data primary_analytic;
	set AHdata.analytic (where=(in_analytic=1)); 
run; *10363; 

* (4); 
data starting_sibs; 
	set AHdata.starting_sibs; ** this is the long-form dataset of the sib sample before dropping anyone for loss to 
						         follow-up or missing data, EXCEPT the small # of people with pair types that aren't 
								 recommended to be included in sibling analyses ; 
run; *5426; 

* need to join to bring in information on the adolescent analytic variables; 
proc sql; 
	create table starting_sibs_vars as select *, w1.aid as analytic_aid from starting_sibs s
	left join starting_full_w1 w1  
	on s.aid = w1.aid; 
quit; 

proc sql; 
	select count(distinct aid) from starting_sibs_vars 
	where analytic_aid =' ';
quit; 	 

* (5); 
** creating using a join; 
** inner join will only keep rows where sib appeared in both OG sib sample and 
   Wave V of the Add Health data ; 

proc sql; 
	create table sibs_w5 as select * from starting_sibs s
	inner join starting_full_w5 w5
	on s.aid=w5.aid;
quit; *3190;  

* (6); 
data sib_analytic; 
	set AHdata.sibling_analytic; ** this is the actual sibling analytic file - so everyone belongs to a pair that was 
									followed to wave V with complete info on needed variables ; 
run; *1796; 

* (7); 
data sib_informative; 
	set AHdata.sib_informative; ** this is the INFORMATIVE sibling dataset - so only sibs who belonged to families with 
								   discordance on both adolescent psychopathology and unintentional injury ; 
run; *127; 

** Run macro on each dataset. Output.; 

ods excel file = "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Output\characterizing_samples.xlsx"
	  options(sheet_interval='NONE'); 

%get_unweighted_descriptives(data=starting_full_w1,injuries=0);

%get_unweighted_descriptives(data=starting_full_w5, injuries=1);

%get_unweighted_descriptives(data=primary_analytic, injuries=1); 

%get_unweighted_descriptives(data=starting_sibs_vars,injuries=0);

%get_unweighted_descriptives(data=sibs_w5, injuries=1);

%get_unweighted_descriptives(data=sib_analytic, injuries=1); 

%get_unweighted_descriptives(data=sib_informative, injuries=1); 

ods excel close; 
