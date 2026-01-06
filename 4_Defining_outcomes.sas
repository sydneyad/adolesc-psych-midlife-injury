
**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Defining outcome variables 
* AUTHOR: Sydney M. Adams 
* LAST UPDATED: 1/5/2026 
* INPUT FILE(S): Wave V mixed-mode survey data (wave5.xpt) 
* OUTPUT FILE(S): w5_outcomes_final.sas7bdat
* RELEVANT RESULTS IN MANUSCRIPT: None 
* 
**************************************************************************************************************;

libname in xport "P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Core Files - Wave V\Wave V Mixed-Mode Survey Data\wave5.xpt";


/* Reading in the Wave V data - just variables necessary to identify participants and define outcomes */ 
data wave5_data; 
	set in.wave5 (keep=AID H5DA2 H5DA1 H5MN9 H5MN10 H5CJ2D H5CJ2E H5CJ2F H5TR22 H5TR23 H5ID1 
					   H5ID11 H5LM5 H5ID9 H5SS4A H5SS4B H5SS4C H5SS4D H5EC5C H5LM27);
run; 

proc contents data=wave5_data;
run; 

/* Beginning to define main injury outcomes */ 

data wave5_outcomes; 
	set wave5_data; 

	/* (1) PAST-YEAR SERIOUS INJURY */ 
			/* Doesn't need re-coded. 
			1 = yes, 0 = no, . = missing */ 

	w5_py_serious_injury = H5DA2; 
	
	/* (2a) PAST-YEAR ASSAULT INJURY */ 
		 /* For primary indicator, first need to access information from 3 variables: H5CJ2D (shot/stabbed), H5CJ2F (beaten up), and H5TR23 
			  (IPV injury). A secondary, more-lenient indicator will also use information from H5CJ2E (someone slapped/hit/kicked/choked you
			  and H5TR22 (your partner slapped/hit/kicked you). */ 
	
		/* H5CJ2D, H5CJ2F, and H5CJ2E already coded as desired 1=yes, 0=no, .=missing) */ 

	w5_py_shot_stabbed = H5CJ2D;
	w5_py_beaten_up = H5CJ2F; 
	w5_py_slapped_hit = H5CJ2E; 

		/* H5TR23 (IPV injury) and H5TR22 (int. partner slapped, hit, kicked etc.) are coded as .=missing, 1=never, 2=has before but not in last year, 
			3-8 as categories of incr. frequency starting with 'once', 97 as legit skip (which we are treating as a 0). 
			Re-coding to binary indicator of (any frequency) past-year injury from IPV. */

	if 3 <= H5TR23 <= 8 then w5_py_ipv_injury = 1; 
		else if H5TR23 in (1,2,97) then w5_py_ipv_injury = 0; 
		else w5_py_ipv_injury=.; 

	if 3 <= H5TR22 <= 8 then w5_py_ipv_slap = 1; 
		else if H5TR22 in (1,2,97) then w5_py_ipv_slap = 0; 
		else w5_py_ipv_slap=.; 

run; 

** Check; 
proc freq data=wave5_outcomes; 
	table H5TR22*w5_py_ipv_slap H5TR23*w5_py_ipv_injury /nocol norow nopercent missing; 
run; 

data wave5_outcomes; 
	set wave5_outcomes; 
	/* (2b) PAST-YEAR ASSAULT INJURY (cont.) */ 

		/* if any of the individual assault injury indicators is 1 then assault injury should =1, 
		BUT if all are missing OR if there's a mix of missing and 0's, then assault is missing. 
		
		Flag py_assault_inj as present if any indicators =1. Else, if any is missing, py_assault_inj is missing.
		Else, (all indicators=0), py_assault_inj = 0. Repeat logic for more-lenient outcome, which also includes 
		slapped/hit/kicked/choked instances. */ 

	if (w5_py_ipv_injury = 1 or w5_py_shot_stabbed = 1 or w5_py_beaten_up = 1) then w5_py_assault_inj = 1; 
		else if (w5_py_ipv_injury = . or w5_py_shot_stabbed = . or w5_py_beaten_up = .) then w5_py_assault_inj = .; 
		else w5_py_assault_inj=0; 

	if (w5_py_ipv_injury = 1 or w5_py_shot_stabbed = 1 or w5_py_beaten_up = 1 or w5_py_slapped_hit = 1 or w5_py_ipv_slap = 1) 
				then w5_alt_lenient_assault_inj = 1; 
		else if (w5_py_ipv_injury = . or w5_py_shot_stabbed = . or w5_py_beaten_up = . or w5_py_slapped_hit = . or w5_py_ipv_slap = .) 
				then w5_alt_lenient_assault_inj = .; 
		else w5_alt_lenient_assault_inj=0; 

	/* (3) PAST-YEAR SUICIDE ATTEMPT */
	   		/* H5MN9 (suicide attempt) is coded such that 1=none, 2-5 = categories of incr. frequency starting 
			with 'once.' Here, re-coding as binary indicator of past-year (any frequency) suicide attempt */ 

	if H5MN9 >= 2 then w5_py_suicide_attempt = 1; 
		else if H5MN9 = 1 then w5_py_suicide_attempt = 0; 
		else w5_py_suicide_attempt = .; 

		/* as an alternate, more conservative outcome: SUICIDE ATTEMPT INJURY (injury/poisoning severe enough to require tx) 
		   note that every legitimate skip (value of 97, 11,839 people) is someone who said "no" to gateway SA question. */ 
	if H5MN10 in(97, 0) then w5_alt_sui_attempt_inj = 0; 
		else if H5MN10 = 1 then w5_alt_sui_attempt_inj =1; 
		else w5_alt_sui_attempt_inj=.; 
run; 

** Checks; 
title "binary suicide attempt indicator vs. frequency indicator"; 
proc freq data=wave5_outcomes; 
	table H5MN9*w5_py_suicide_attempt /norow nopercent missing; 
run; 
title;

title "AH indicator vs. re-coded for severe suicide attempt inj - remember 97=legskip"; 
proc freq data=wave5_outcomes; 
	table H5MN10*w5_alt_sui_attempt_inj /norow nopercent missing; 
run;
title; 

title "primary vs. alternate/strict suicide attempt inj indicator"; 
proc freq data=wave5_outcomes; 
	table w5_py_suicide_attempt*w5_alt_sui_attempt_inj / norow nopercent nocol missing; 
run;
title; 

title "individual assault vars by combined assault indicator"; 
proc freq data=wave5_outcomes; 
	table w5_py_ipv_injury*w5_py_assault_inj
		  w5_py_shot_stabbed*w5_py_assault_inj 
		  w5_py_beaten_up*w5_py_assault_inj / norow nopercent missing;
run; 

title "individual assault vars by combined ALTERNATE assault indicator"; 
proc freq data=wave5_outcomes; 
	table w5_py_ipv_injury*w5_alt_lenient_assault_inj
		  w5_py_shot_stabbed*w5_alt_lenient_assault_inj 
		  w5_py_beaten_up*w5_alt_lenient_assault_inj
		  w5_py_slapped_hit*w5_alt_lenient_assault_inj
		  w5_py_ipv_slap*w5_alt_lenient_assault_inj / norow nopercent missing;
run; 

/* Continuing to add outcomes of interest:
   secondary injury outcome (falls) + midlife circumstances outcomes */

data wave5_outcomes2; 
	set wave5_outcomes; 

	/* (4) (BINARY) HIGH-FREQUENCY FALLS */
		/* Defining high-frequency of falls as 3+ falls in last year.
		   H5DA1 can be . (missing), 0 (never), or 1-6 (indicators of increasing freq. of falls, where 
		   3 is "3-4 times"). Re-coding to binary indicator of high frequency (3+) falls below. */  

	if 3 <= H5DA1 <= 6 then w5_bin_hf_falls =1; 
			else if 0 <= H5DA1 < 3 then w5_bin_hf_falls =0;
			else w5_bin_hf_falls=.; 

	/* (5) SELF-RATED HEALTH */ 
		/* H5ID1 is defined as 1 (excellent), 2 (very good), 3 (good), 4 (fair), 5 (poor), or . (missing).
			Re-coding to binary (1,2,3 --> 0; 4, 5 --> 1) indicator of fair-to-poor health. */ 

	if H5ID1 in(1,2,3) then w5_fair_poor_health=0; 
		else if H5ID1 in(4,5) then w5_fair_poor_health=1; 
		else w5_fair_poor_health=.; 

	/* (6) SOCIAL SUPPORT */
		/* AH measure indicates if one can rely on: spouse/partner (H5SS4A), 
		   children (H5SS4B), family members (H5SS4C), and friends (H5SS4D). 
		   0=no, 1=yes, 3=NA (which we're treating as no), .=missing.
		   
		   Re-coding to binary indicator of lacking support. As with coding of assault inj, if any 
		   indicator =1 (supported) code individual as supported (0), but if mix of missing and lacking-support,
		   code to missing. If all indicate lacking support, lacks-support=1. */

	if (H5SS4A=1 or H5SS4B=1 or H5SS4C=1 or H5SS4D=1) then w5_lacks_support=0; 
		else if (H5SS4A=. or H5SS4B=. or H5SS4C=. or H5SS4D=.) then w5_lacks_support=.; 
		else w5_lacks_support=1; 
	
	/* (7) EMPLOYMENT STATUS */ 
		/* AH includes both an indicator of working for pay (H5LM5) and an indicator of current working status (H5LM27). 
		   For QA, here code both.
		   Our unemployment outcome is defined as (a) being in the labor force and (b) having work status (H5LM27) as unemployed or laid off.
		   Per (a), need to drop out individuals not in labor force. So set to missing if H5LM27=4, 6, 7, 8, 9, or 10 (permanently 
		   disabled, unemployed and not looking for work, student, keeping house, retired, or other). */ 

	if H5LM5=1 then w5_notworkpay=0; 
		else if H5LM5 in(2,3) then w5_notworkpay=1; 
		else w5_notworkpay=.; 

	/* Note: leg-skip for H5LM27 appears to indicate either a working-for-pay status as employed (thus unemployed=0) or missing (thus unemployed=.)  
		So pulling in information from H5LM5 to ensure that all those with missingness on working for pay are treated as unemployed=. 
		rather than unemploed=0 */ 

	if H5LM27 in(1,5) then w5_unemployed=1; /* 1=laid off, 5=unemployed and looking for work*/ 
	 	else if H5LM27 in(4,6,7,8,9,10) or H5LM27=. or H5LM5=. then w5_unemployed=.; /* not in work force OR missing info */ 
	 	else w5_unemployed =0; /* OTHERWISE, enforce that leg-skip, temporarily disabled/sick leave, 
								  and maternity/paternity all have unemployed = 0. */ 

	/* (8) HEALTH INSURANCE STATUS */
		/* H5ID9 has several possible values, we want an indicator of lack-of-insurance (15) 
		   Also note, treating 14 ("I do not know what my health insurance is") as missing. 
		   Any other non-missing value of H5ID9 indicates some type of health insurance. */

	if H5ID9=15 then w5_uninsured=1; 
		else if (H5ID9=14 or H5ID9=.) then w5_uninsured=.;  
		else w5_uninsured=0; 

	/* (9) UNMET HEALTHCARE NEED */ 
		/* H5ID11 is already coded as desired (1=yes to question about unmet need) */ 

	w5_unmet_hc_need=H5ID11; 

	/* (10) HOUSEHOLD (NON-MORTGAGE, NON-EDUCATION) DEBT */ 
		/* Coded as 1=none, 2-9 = incr. frequency -  re-coding so that 0=none, 1-8 are the new values of the 
		   subsequent categories (which then also correspond to the format in the proc below). 
		   NOTE: This outcome is re-coded to 3 levels prior to analyses, in script #5 */ 

	if H5EC5C=1 then w5_amount_debt=0; 
		else if H5EC5C=. then w5_amount_debt=.; 
		else w5_amount_debt = (H5EC5C-1); 
run; 

/* Creating format for amount_debt */ 

proc format; 
	value debt 
		0="None"
		1="< $10,000"
		2="$10,000-$24,999"
		3="$25,000-$49,999"
		4="$50,000-$99,999"
		5="$100,000-$249,999"
		6="$250,000-$499,999"
		7="$500,000-$999,999"
		8="$1,000,000+"
		; 
run;

**Checks; 
proc freq data=wave5_outcomes2; 
	table H5DA1*w5_bin_hf_falls /* pay attention to 3-6 vs. 0-2 */ 
		  H5ID1*w5_fair_poor_health /* pay attention to 4-5 vs. 1-3 */ 
		  H5SS4A*w5_lacks_support 
		  H5SS4B*w5_lacks_support
		  H5SS4C*w5_lacks_support
		  H5SS4D*w5_lacks_support
		  H5LM5*w5_notworkpay /* pay attention to 2-3 vs. 1 */
		  H5LM27*w5_unemployed /* pay attention to 1,5 vs. 2,3,997 vs. all else */ 
		  H5ID9*w5_uninsured /* pay attention to 15 vs. other, and 14 as missing */ 
		  H5EC5C*w5_amount_debt
			/ norow nopercent missing;
		format w5_amount_debt debt.; 
run; 
title; 

/* To help with later reporting on derivation of analytic sample, create indicator of 
being dropped from unemployment analysis due to missingness vs. due to not being in labor force. */
data wave5_outcomes2; 
	set wave5_outcomes2; 
	length qa_unempl_miss $15.; 
	if H5LM27=. or H5LM5=. then qa_unempl_miss = "true-miss"; 
		else if H5LM27 in(4,6,7,8,9,10) then qa_unempl_miss = "not-labor-force"; 
		else qa_unempl_miss = "included"; 
run; 

proc freq data=wave5_outcomes2; 
	table w5_notworkpay*w5_unemployed /nocol nopercent missing;
run; 

proc contents data=wave5_outcomes2; 
run; 


*****************************************************************; 
**************** OUTPUT DATA FILE + DESCRIPTIVES ***************; 
*****************************************************************; 

/* Restricting to vars needed for analyses, creating output dataset */ 
data wave5_outcomes_final; 
	set wave5_outcomes2 (keep=aid w5_amount_debt w5_bin_hf_falls w5_unemployed 
						      w5_fair_poor_health w5_lacks_support w5_py_assault_inj w5_alt_lenient_assault_inj
							  w5_py_serious_injury w5_py_suicide_attempt w5_alt_sui_attempt_inj
							  w5_uninsured w5_unmet_hc_need qa_unempl_miss); 
run; 

proc contents data=wave5_outcomes_final; 
run;  

proc sort data=wave5_outcomes_final; by aid; run; 
proc sort data=wave5_outcomes_final nodupkey out=dup_check; by aid; run;

libname AHdata "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Intermediate_Data" ; 
data AHdata.w5_outcomes_final; 
	set wave5_outcomes_final; 
run; * n=12,300;
