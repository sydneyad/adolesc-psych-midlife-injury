**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Defining covariates
* AUTHOR: Sydney M. Adams, some code adapted from K. Dent and L. Richmond-Rakerd
* LAST UPDATED: 12/18/2025 
* INPUT FILE(S):  Wave I interview data (allwave1.xpt), Wave V mixed-mode survey data (wave5.xpt), 
*                 Constructed SES data (conses.xpt), 
* OUTPUT FILE(S): AHdata.final_covariates
* RELEVANT REUSLTS IN MANUSCRIPT: None 
*
**************************************************************************************************************;

libname in1 xport "P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Core Files - Wave I\Wave I In Home Interview Data\allwave1.xpt";

*** Read in AIDs and covariates needed from Wave 1. Re-name to more-descriptive names.; 
data wave1; 
	set in1.allwave1 (keep=AID BIO_SEX AH_PVT H1GI8 H1GI6A H1GI6B H1GI6C H1GI6D H1GI6E H1GI4 imonth iyear iday H1GI1M H1GI1Y);
	rename H1GI8 = w1_race_one 
		   H1GI6A = w1_race_white H1GI6B = w1_race_black H1GI6C = w1_race_amind H1GI6D = w1_race_asian H1GI6E = w1_race_other 
	   	   H1GI4 = w1_ethnicity
      	   H1GI1M = w1_birth_mo H1GI1Y = w1_birth_yr imonth = imonth1 iyear = iyear1 iday = iday1
		   bio_sex = w1_sex 
		   AH_PVT = w1_cog_ability; 
run; *n=20,745; 

*** Read in interview date from Wave V, which is needed to derive Wave V age. ; 
libname in2 xport "P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Core Files - Wave V\Wave V Mixed-Mode Survey Data\wave5.xpt";
data wave5; 
	set in2.wave5(keep = aid imonth5 iyear5); 
	rename imonth5 = w5_intvw_month iyear5 = w5_intvw_year; 
run; *n=12,300; 

*** Merge Wave 1 + Wave 5, using adolescent ID; 
proc sort data = wave1; 
	by aid;
proc sort data = wave5; 
	by aid;

data w1w5; 
	merge wave1 wave5;
	by aid;
run; *n=20,745; 

*** Create formats for sex, ethnicity, race ; 
proc format ; 
value sexf /* note 1=M, 2=F in original AH bio_sex */ 
	1 = 'M'
	2 = 'F' ;
value ethnicityf /* note 1=H 0=Non  in original AH ethnicity */ 
	0 = 'Non-Hispanic' 
	1 = 'Hispanic' ; 
value racef /*1-5 are same as in AH indicator (e.g. H1GI8). 6 is new, corresponds to add'l multiracial 
			var in w1_race2, described below. */ 
	1 = 'White' 
	2 = 'Black or African American' 
	3 = 'American Indian or Native American' 
	4 = 'Asian or Pacific Islander' 
	5 = 'Other'  
	6 = 'Multiracial'; 
run; 

*** Various re-codes to demographic variables, see descriptioins; 
data w1w5_v2; 
	set w1w5 ; 
	format w1_race1 racef. w1_race2 racef. w1_ethnicity ethnicityf. w1_sex sexf.; 

/* (1) SEX */ 
	/* Set 6,8 to missing. 6=refused, 8=don't know */ 
	if w1_sex in (6,8) then w1_sex=.; 

/* (2) ETHNICITY */ 
	/* Set 6,8 to missing. 6=refused, 8=don't know */ 
	if w1_ethnicity in (6,8) then w1_ethnicity = . ; 

/* (3) RACE (1 & 2) */ 
	/* First note missingness. 6=refused, 7=leg skip, 8=don't know, 9=not applicable. 
		Make an array of each of the 6 individual race indicators, and then uses it to 
		reset a value of 6, 7, 8, or 9 in any of these indicators to missing. */ 

	array race {6} w1_race_white w1_race_black w1_race_amind w1_race_asian w1_race_other w1_race_one; 
	do i = 1 to 6 ; 
		if race[i] in (6,7,8,9) then race[i] = . ; 
	end ; 

	/* Then make two indicators of race following 2 patterns of rules w/ different handling of multiracial.
	w1_race1: Individuals who endorsed multiple racial categories are categorized as the racial category 
	       that they indicated best described their background in w1_race_one. If they endorsed multiple 
		   categories and then didn't have a response for w1_race_one, their race is listed as missing. 
		   If they endorsed no categories but had a response for w1_race_one, their race is listed as the 
	       value from w1_race_one.

	w1_race2: Alternate rule. Individuals who endorsed multiple racial categories are categorized as a new 
		   category, "multiracial," regardless of if they had a response for wi_race_one. */ 

/* how many racial categories endorsed? */ 
	race_sum = sum(w1_race_white, w1_race_black, w1_race_amind, w1_race_asian, w1_race_other); 

/* if endorsed multiple categories, set race1 to value of the one category chosen by ptcpt to best describe race
								    set race2 to multiracial. */ 
	if race_sum > 1 then do; 
		w1_race1 = w1_race_one; 
		w1_race2 = 6 ; 
		end; 

/* if had missingness on ALL individual categories, set both race1 and race2 to the category chosen by ptcpt to 
	best describe their race if possible. NOTE. Freqs below suggest this didn't apply to anyone (everyone with 
	missingness on all individ categories also was missing for w1_race_one. */ 

	else if race_sum = . then do; 
		w1_race1 = w1_race_one;
		w1_race2 = w1_race_one; 
		end; 

/* if only 1 racial category was endorsed, set both race1 and race2 to the indicated racial category */ 
	else if race_sum = 1 then do ; 
		if w1_race_white = 1 then do; 
			w1_race1 = 1; 
			w1_race2 = 1; 
			end; 
		if w1_race_black = 1 then do; 
			w1_race1 = 2; 
			w1_race2 = 2; 
			end; 
		if w1_race_amind = 1 then do; 
			w1_race1 = 3;
			w1_race2 = 3; 
			end; 
		if w1_race_asian = 1 then do; 
			w1_race1 = 4;
			w1_race2 = 4; 
			end;
		if w1_race_other = 1 then do;
			w1_race1 = 5;
			w1_race2 = 5; 
			end; 
		end ; 

/* otherwise, we have no non-missing info on race, so set both indicators to missing. */ 
	else do; 
		w1_race1=.;
		w1_race2=. ; 
	end; 
run; 

*** Check two versions of race indicator; 
proc freq data=w1w5_v2; 
	table w1_race1 w1_race2 / missing; 
run; 

proc freq data=w1w5_v2; 
	table w1_race1*w1_race2 / missing norow nocol nopercent; 
run; 

*** (4) AGE AT WAVE V; 

data w1w5_v3; 
	set w1w5_v2; 

	/* first use w1 invtvw date and w1 birthdate to calc age at W1 */ 
	w1_intvw_date = mdy(imonth1, iday1, iyear1); 
	w1_bdate = mdy(w1_birth_mo, 15, w1_birth_yr); 
	w1_age = floor((w1_intvw_date - w1_bdate) / 365.25);

	/* then use w5 intvw date and w1 birthdate calc age at W5 */ 
	w5_intvw_date = mdy(w5_intvw_month, 15, w5_intvw_year); 
	w5_age = floor((w5_intvw_date - w1_bdate) / 365.25);
run;

/* Check missingness due to missing birthdate */ 
proc means data=w1w5_v3 n nmiss; 
	var w1_intvw_date w1_bdate w1_age w5_intvw_date w5_age; 
run; 

proc means data=w1w5_v3 min p25 median p75 max mean maxdec=1; 
	var w1_age w5_age; 
run; 
	
/* (5) COGNITIVE ABILITY 
	  Already coded as desired, but look at descriptives. Standardized to mean=100, stdev=15. Note missingness. */ 

proc univariate data=w1w5_v3; 
	var w1_cog_ability;
	histogram; 
run; 

/* (6) ADOLESCENT SES (Social Origins Score) 

	   Pull from consens.xpt. SESPC_AL indicates social origins score, which has been 
       transformed to M=0, SD=1. Note missingness. */ 

libname in3 xport "P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Constructed Files\Constructed SES Variables\conses.xpt";

data ses_data; 
	set in3.conses (keep=AID SESPC_AL);
	rename sespc_al=w1_ses; 
	aid_c=put(aid,8.); /* aid is numeric in the conses file even though it is character elsewhere, so switch to character 
			 			  to enable join on aid. */ 
run; 

proc univariate data=ses_data; 
	var w1_ses;
	histogram; 
run; 


*****************************************************************; 
**************** JOIN, OUTPUT DATA FILES ************************; 
*****************************************************************; 

** Just keep needed vars; 
data covariates; 
	set w1w5_v3 (keep = aid race_sum w1_age w1_bdate w1_ethnicity w1_intvw_date w1_race1 w1_race2 
						w1_sex w1_cog_ability w5_age w5_intvw_date); 
run; 

libname AHdata "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Intermediate_Data";

** Join in SES information; 
proc sql; 
	create table AHdata.final_covariates as select c.*, s.w1_ses from covariates c
	full join ses_data s on c.aid=s.aid_c;  
	quit;
run; 

proc contents data=AHdata.final_covariates; 
run; 

** Check descriptives; 
proc freq data=AHdata.final_covariates; 
	table w1_ethnicity w1_race1 w1_race2 w1_sex / nocum missing; 
run; 

proc means data=AHdata.final_covariates n nmiss min p25 median p75 max mean std mode maxdec=2 nolabels; 
	var w1_cog_ability w1_ses w5_age; 
run; 

ods select histogram; 
proc univariate data=AHdata.final_covariates; 
	var w1_cog_ability w1_ses w5_age; 
	histogram;
run; 
