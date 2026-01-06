**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Identifying relevant weights, region, and cluster variables, plus flagging the "starting population" 
* AUTHOR: Sydney M. Adams 
* LAST UPDATED: 12/18/2025 
* INPUT FILE(S): Wave V Mixed-Mode Survey Weights (weights5.xpt) 
* OUTPUT FILE(S): miss_weights_cluster_region.xlsx, flag_missing_designvars.sas7bdat 
* RELEVANT RESULTS IN MANUSCRIPT: None 
*
**************************************************************************************************************;

libname in xport "P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Core Files - Wave V\Wave V Mixed-Mode Survey Weights\weights5.xpt"; 

*** Reading in Wave V cross-sectional survey weight, region (strata) indicator, and school ID (cluster variable).; 

data weights; 
	set in.weights5 (keep= AID PSUSCID REGION GSW5); 
run; 

*check; 
proc contents data=weights; 
run; 

proc means data=weights n nmiss; 
	var region gsw5; 
run; 

*** Flag participants with missing design variables. Note 999 indicates missing for school ID. ; 

data flag_missing_weights; 
	set weights; 
	if region=. or gsw5=. or psuscid="999" then missing_design_vars=1; 
		else missing_design_vars=0; 
run; 

proc freq data=flag_missing_weights; 
	table missing_design_vars; 
run; 

*** Output dataset with flags for missing design variables, to use to identify analytic cohort. ; 
proc sort data=flag_missing_weights; by aid; run; 

libname AHdata "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Intermediate_Data"; 

data AHdata.flag_missing_designvars; 
	set flag_missing_weights; 
run; *n=12,300; 
