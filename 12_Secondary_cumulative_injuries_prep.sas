**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Preparing an analytic file for secondary analysis predicting 
*                  count of waves at which ptcpt reported a past-year injury 
* AUTHOR: Sydney M. Adams 
* INPUT FILE(S): AHdata.analytic, allwave1.xpt, wave2.xpt, wave4.xpt
* OUTPUT FILE(S): sec_injwaves.csv (is modified and read-in to MPlus for analysis) 
* RELEVANT RESULTS IN MANUSCRIPT: 
* 	See descriptive information reported in Table S1, row "Cumulative Injury Reports Across Waves"
*
**************************************************************************************************************;

*** formats; 
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

*** reading in analytic file - this analysis will use a SUBSET of those 
   ptcpts. also, can re-use the wave V unintentional injury indicator. ; 
libname AHdata "P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Intermediate_Data"  ; 
proc contents data=AHdata.analytic; run; 
data main_analytic; set AHdata.analytic; run; 

*** reading in data from waves 1,2,4 to get injury info; 
libname wave1 xport 'P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Core Files - Wave I\Wave I In Home Interview Data\allwave1.xpt' ; 
libname wave2 xport 'P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Core Files - Wave II\Wave II In Home Interview Data\wave2.xpt' ; 
libname wave4 xport "P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Core Files - Wave IV\Wave IV In Home Interview Data\wave4\wave4.xpt" ; 

data w1; 
	set wave1.allwave1 (keep= AID H1GH54); 
	rename H1GH54=w1_py_inj_seriousness;  
run; *n=20,745; 

data w2; 
	set wave2.wave2 (keep= AID H2GH47);
	rename H2GH47=w2_py_inj_seriousness; 
run; *n=14,738; 

data w4(rename=(H4ID7=w4_py_serious_injury)); 
	set wave4.wave4 (keep=AID H4ID7) ; 
	if H4ID7 in(6,8) then H4ID7=.; *6=refused,8=dk; 
run; *n=15,701; 

proc contents data=w1; 
proc contents data=w2;  
proc contents data=w4; 
run; 

*w1 and w2 ask about seriousness/extent of worst injury in past-year; 
  * 1=very minor, 2=minor, 3=serious, 4=very serious, 5=extremely serious,
    6=refused, 8=don't know, 9=not applicable ; 
proc freq data=w1; table w1_py_inj_seriousness; run; 
proc freq data=w2; table w2_py_inj_seriousness; run; 

*w4 and w5 ask if they had a serious injury in past-year; 
proc freq data=w4; table w4_py_serious_injury /missing; run; 

proc freq data=main_analytic; table w5_py_serious_injury /missing; run; 

*** Join - in steps; 
proc sql; 
	create table analytic_w1 as select m.aid, psuscid, region, gsw5, analytic_wt,
                 w5_py_serious_injury, in_analytic, analytic_wt,
				 w1_sex, w1_hispanic_ethnicity, w1_race, w5_age, 
				 w1_ses, w1_cog_ability, any_adol_mh, int_adol_mh,
				 ext_adol_mh, w1_py_inj_seriousness /* just needed vars */ 
                 from main_analytic m
	left join w1 /* left join because i don't want anyone 
	                who wasn't in main analytic sample, and I 
	                need to keep all from analytic to use 
	                weights correctly. */ 
	on m.aid=w1.aid; 
	quit;
run; *n = 12,057;  

proc print data=analytic_w1 (obs=5); run; 

proc sql; 
	create table analytic_w1_w2 as select * from analytic_w1 a 
	left join w2
    on a.aid=w2.aid; 
	quit;
run; *n=12,057; 

proc print data=analytic_w1_w2 (obs=5); run; 

proc sql; 
	create table analytic_w1_w2_w4 as select * from analytic_w1_w2 a 
	left join w4
    on a.aid=w4.aid; 
	quit;
run; *n=12,057; 

proc contents data=analytic_w1_w2_w4; run; 

proc means data=analytic_w1_w2_w4 n nmiss mean; run; 

data analytic_accuminj; 
	set analytic_w1_w2_w4; 
	/* recategorize 1 (very minor), 2 (minor), 9 (not applic) to 0,
	   3(serious), 4(very serious), 5(extrem. serious) to 1,   
	   6 refused, 8 don't know to missing */  
	if w1_py_inj_seriousness in(1,2,9) then w1_py_serious_injury=0; 
		else if w1_py_inj_seriousness in(3,4,5) then w1_py_serious_injury=1; 
		else w1_py_serious_injury=.; 

	if w2_py_inj_seriousness in(1,2,9) then w2_py_serious_injury=0; 
		else if w2_py_inj_seriousness in(3,4,5) then w2_py_serious_injury=1; 
		else w2_py_serious_injury=.; 
run; 

proc freq data=analytic_accuminj; 
	table w1_py_inj_seriousness*w1_py_serious_injury 
	      w2_py_inj_seriousness*w2_py_serious_injury /missing; 
run; 

proc freq data=analytic_accuminj; 
	table w1_py_serious_injury w2_py_serious_injury w4_py_serious_injury w5_py_serious_injury /nocum;
run; 

*** check missingness across waves; 
data missing_accum_inj;
	set analytic_accuminj;  
	nmiss_injwaves=nmiss(w1_py_serious_injury,w2_py_serious_injury,w4_py_serious_injury, w5_py_serious_injury); 
run;

proc freq data=missing_accum_inj; table nmiss_injwaves ; run; 

*** create TWO new in_analytic indicators for this analysis: 
	first 'lenient' requiring nmiss of 1 or fewer (i.e., requiring that they have nonmissing 
    data for at least 3 of the 4 included waves) 
    second 'conservative' requiring nmiss of 0 (i.e. nonmissing data for all 4 waves).
	Note lenient is used in study. Conservative retained for check only.; 

proc freq data=missing_accum_inj; 
	table in_analytic*nmiss_injwaves /nopercent norow nocol; 
run; 

data accum_inj_analytic; 
	set missing_accum_inj; 
	* (1) ; 
	in_sec_accuminj_analytic_len = in_analytic; 
	if nmiss_injwaves>1 then in_sec_accuminj_analytic_len = 0; 
	* (2) ; 
	in_sec_accuminj_analytic_cons = in_analytic; 
	if nmiss_injwaves>0 then in_sec_accuminj_analytic_cons=0; 

run; 

proc freq data=accum_inj_analytic; 
	table in_analytic*in_sec_accuminj_analytic_len
		  in_analytic*in_sec_accuminj_analytic_cons  
	      in_sec_accuminj_analytic_len*in_sec_accuminj_analytic_cons /missing; 
run;  
 
proc freq data=accum_inj_analytic; 
	where in_analytic=1 and in_sec_accuminj_analytic_len=0; 
	table w1_py_serious_injury w2_py_serious_injury w4_py_serious_injury w5_py_serious_injury /missing;
run; 

proc freq data=accum_inj_analytic; 
	where in_sec_accuminj_analytic_len=1; 
	table nmiss_injwaves w1_py_serious_injury w2_py_serious_injury w4_py_serious_injury w5_py_serious_injury /missing;
run; 

proc freq data=accum_inj_analytic; 
	where in_sec_accuminj_analytic_cons=1; 
	table nmiss_injwaves w1_py_serious_injury w2_py_serious_injury w4_py_serious_injury w5_py_serious_injury /missing;
run; 

*** Create outcome variable. Also 2 weight variables for the 2 respective cohorts.; 
data accum_inj_analytic2; 
	set accum_inj_analytic; 
	sum_injury_waves = sum(w1_py_serious_injury, w2_py_serious_injury, w4_py_serious_injury, w5_py_serious_injury);

	*set sum_injury_waves to missing if 2 or more waves had missing data. note, this corresponds to primary
	"lenient" approach - in a sensitivity test we also want to exclude individuals with 1 or more waves of missing
	data, but this will be accomplished using the subpopulation/weight variable approach. ; 
	if nmiss_injwaves>1 then sum_injury_waves=.; 

	** note do not need these for mplus but do need them to generate correct weighted frequencies, below ; 
	sec_accuminj_wt_len = analytic_wt; 
	if in_sec_accuminj_analytic_len=0 then sec_accuminj_wt_len=0.00001; 

	sec_accuminj_wt_cons = analytic_wt; 
	if in_sec_accuminj_analytic_cons=0 then sec_accuminj_wt_cons=0.00001; 
run; 
* Checks; 
proc means data=accum_inj_analytic2; 
	var sec_accuminj_wt_len; 
	where in_sec_accuminj_analytic_len=1; 
run; 

proc means data=accum_inj_analytic2; 
	var sec_accuminj_wt_len; 
	where in_sec_accuminj_analytic_len=0; 
run; 

proc means data=accum_inj_analytic2; 
	var sec_accuminj_wt_cons; 
	where in_sec_accuminj_analytic_cons=1; 
run; 

proc means data=accum_inj_analytic2; 
	var sec_accuminj_wt_cons; 
	where in_sec_accuminj_analytic_cons=0; 
run; 

*** Look at frequencies for contrast of interest, MH by sum of accumulated injury-waves ;

proc freq data=by_mh (where=(in_sec_accuminj_analytic_len=1));
	table any_adol_mh*sum_injury_waves /nocol nopercent;
run; 

** does this hold if we don't allow missingness at any of the waves?;

proc freq data=by_mh (where=(in_sec_accuminj_analytic_cons=1));
	table any_adol_mh*sum_injury_waves /nocol nopercent;
run; 

** Examine weighted prevalence of injury at each included wave - reported in Table S1 in paper.; 
proc surveyfreq data=accum_inj_analytic2; 
	table w1_py_serious_injury w2_py_serious_injury w4_py_serious_injury 
		w5_py_serious_injury; 
	cluster psuscid; 
	strata region; 
	weight sec_accuminj_wt_len; 
run; 

*** Prepare data to output as CSV

	Remove vars not needed for analyses, rename to shorter names, set vars
    stored as characters (psuscid, aid) to numeric format instead, create 
	dummy vars for categorical race variable + dummy var for male sex; 

proc contents data=accum_inj_analytic2; run; 

data sec_inj_waves (drop=w1_sex w1_race w1_hispanic_ethnicity) ; 
	set accum_inj_analytic2; 
	drop analytic_wt in_analytic w1_py_inj_seriousness w1_py_serious_injury w2_py_inj_seriousness 
		 w2_py_serious_injury w4_py_serious_injury w5_py_serious_injury ;

    rename any_adol_mh = any_mh; 
	rename int_adol_mh = int_mh; 
	rename ext_adol_mh = ext_mh; 
	rename in_sec_accuminj_analytic_cons = con_samp; 
	rename in_sec_accuminj_analytic_len  = len_samp; 
	rename sec_accuminj_wt_cons = con_wt; 
	rename sec_accuminj_wt_len  = len_wt; 
    rename nmiss_injwaves = miss_wvs; 
	rename sum_injury_waves = n_inj_wv; 
    rename w1_cog_ability = w1_cog; 

	if w1_hispanic_ethnicity=1 then hispanic=1; 
		else if w1_hispanic_ethnicity=. then hispanic=.; 
		else hispanic=0;
	 /* note: w1_hispanic_ethnicity was already dummy-coded but it reads into CSV as formatted text, 
		which I don't want. */ 

	if w1_sex=2 then female=1; 
		else if w1_sex=. then female=.; 
		else female=0; 
 
	* w1_race=1 indicates white, which will be treated as ref. ; 
	if w1_race=2 then black=1; 
		else black=0; 
	if w1_race=3 then amer_in=1; 
		else amer_in=0; 
	if w1_race=4 then asian_pi=1; 
		else asian_pi=0; 
	if w1_race=5 then race_oth=1; 
		else race_oth=0; 
	if w1_race=6 then multirac=1; 
		else multirac=0; 
	if w1_race=. then do; 
		black=.; amer_in=.; asian_pi=.; race_oth=.; multirac=.; 
		end;
run;

proc sort data=sec_inj_waves; by aid; run; 

proc contents data=sec_inj_waves; run; 

proc print data=sec_inj_waves (obs=5); run; 
** Cofnrim N; 

proc sql; 
	select count(*) as main_lenient_n, max(miss_wvs) as max_miss_wvs, mean(n_inj_wv) as mean_n_inj_wv,
	mean(any_mh) as prev_mh 
	from sec_inj_waves
    where len_samp=1; 
quit; 
title; 

proc sql; 
	select count(*) as check_conservative_n, max(miss_wvs) as max_miss_wvs, mean(n_inj_wv) as mean_n_inj_wv,
	mean(any_mh) as prev_mh 
	from sec_inj_waves
    where con_samp=1; 
quit; 
proc surveymeans data=sec_inj_waves nobs nmiss q1 median q3 min max mean std;  
	var n_inj_wv ; 
	cluster psuscid; 
	strata region; 
	weight gsw5; 
	domain len_samp; 
run; 

proc sort data=sec_inj_waves out=sorted_bymh; by any_mh; run; 
proc surveymeans data=sorted_bymh nobs nmiss q1 median q3 min max mean std;  
	var n_inj_wv ; 
	by any_mh; 
	cluster psuscid; 
	strata region; 
	weight gsw5; 
	domain len_samp; 
run; 

proc surveyfreq data=sec_inj_waves; 
	table n_inj_wv; 
	cluster psuscid; 
	strata region; 
	weight len_wt; 
run;

*** Drop the wt variables no longer needed, to save confusion and read less into mplus; 
** Also create alternate indicator of n_inj_wv that collapses 3+4, given small counts for 4; 
** Note this is retained for check purposes but did not alter findings and is not reported in text.; 
data sec_inj_waves; 
	set sec_inj_waves; 
	drop len_wt con_wt; 
	n_injwv2 = n_inj_wv; 
	if n_inj_wv=4 then n_injwv2 =3; 
run; 

proc contents data=sec_inj_waves; run; 

*** Output dataset as CSV;  

proc export data=sec_inj_waves
    outfile="P:\AddHealth\Contract\29042102-RichmondRakerd\Work\Sydney Adams\619_Midlife_injury_project\Code\MPlus_sec_analysis\sec_injwaves.csv"
	dbms=csv
	replace;
run; 

* !!NOTE!! before reading that CSV into M-plus, need to make a revised version 
that deletes the header row and also replaces all blank cells with . ; 

