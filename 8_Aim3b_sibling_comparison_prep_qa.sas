**************************************************************************************************************;
*
* PROJECT: Add Health Adolescent Psychopathology & Midlife Injury 
* PROGRAM PURPOSE: Reading in sibling data and merging with analytic file  
* AUTHOR: Sydney M. Adams
* INPUT FILE(S): analytic_exp_sibs.sas7bdat (must run SAS code files 1-5 before running this!) 
*				  pairs.xpt 
* 
* OUTPUT FILE(S): AHdata.starting_sibs.sas7bdat, AHdata.sibling_analytic.sas7bdat
* RELEVANT RESULTS IN MANUSCRIPT: 
	Figure S2 - Deriving sibling-comparison sample  
	Table S1 - See reports of within-sibling concordance on SES in "Socioeconomic Status" row. 
* !NOTE! A transpose step in this script will throw an error in SAS Enterprise Guide but run without issue in SAS 9.3. 
*
**********************************************************************************************************************; 

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

** Bring in 'expanded' analytic file - this includes individuals with missingness on complex survey design variables,
   as those variables are predominantly missing among individuals in the sibling data + are not needed for sibling-comparison. ; 
data analytic_exp_sibs; set AHdata.expanded_analytic_forsibs; run; 
proc contents data=analytic_exp_sibs; run; *N=12,300; 

*** Read in sibling data.
	This file is in wide forma,  with each row representing a sibling pair (2 AIDs) 
	PAIR = unique pair ID number
	FAMID = unique family ID number 
	SIBCL2 = most-differentiated sibling classification variable. Keeping just to get familiar w/ data, won't be using.
	SIBCL4 = a sibling classification variable that just differentiates cousins, DZ twins, MZ twins, uncertain zygosity twins, 
			 other full sibs, half-sibs, not-related-reared-together-pairs (exl. aunt/uncle, niece/nephew, group home, spouse, inlaw pairs), 
			 and missing (indicates aunt/uncle, niece/nephew etc.). This is the recommended sibling classification variable and the one
			 used in this project. 
	AID_1 = sibling 1 ID 
	AID_2 = sibling 2 ID ; 

libname in xport "P:\AddHealth\Contract\29042102-RichmondRakerd\Data\Sibling Files\Adolescent Pairs Data\pairs.xpt"; 

data sibs; 
	set in.pairs (keep= PAIR AID_1 AID_2 FAMID SIBCL2 SIBCL4); 
run; 

proc contents data=sibs; run; 

proc freq data=sibs; table sibcl4 sibcl2*sibcl4 / nocol nopercent norow missing; run; 

** We ultimately will drop sibs with those types marked missing. Label them for QA and to avoid confusion in joins.; 
data sibs; 
	length sibcl4 $8;
	set sibs; 
	if sibcl4 = " " then sibcl4 = "delete"; 
run; 

proc freq data=sibs; table sibcl4 sibcl2*sibcl4 /nocol norow missing; run; 

proc sql; 
	select count (distinct AID_1) as distinct_aid1, 
		   count (distinct AID_2) as distinct_aid2,
		   count (distinct pair) as distinct_pairs,
		   count (distinct famid) as distinct_families, 
		   count(*) as n_rows 
	from sibs; 
quit; 

** Note that sibs has 1 row per adolescent pair. There may be multiple pairs w/ the same family ID,
   and the same AID can contribute to multiple pairs. ; 

proc sort data=sibs out=sorted_qa; by famid; run; 


/* PRELIM ANALYSIS OF SIB PAIRS DATA */ 
*** With data in wide-format, examine discordance between siblings on characteristics of interest.; 
** Macro INNER joins in analytic data, first for AID_1 then for AID_2.; 

%macro wide_join_sib_analytic(sibsdata=, number=);
proc sql; 
	create table widesib_analytic_&number as select s.*, /* take all vars from sibs file */
	a.w1_race as race_adol&number, a.w1_sex as sex_adol&number, a.w1_hispanic_ethnicity as ethnicity_adol&number, 
	a.w5_py_serious_injury as inj_adol&number, a.w1_cog_ability as cog_adol&number, 
	a.int_adol_mh as int_adol&number, a.ext_adol_mh as ext_adol&number, a.w1_ses as ses_adol&number,
	a.w1_age as w1_age_adol&number, a.w5_age as w5_age_adol&number, 
	a.any_adol_mh as any_mh_adol&number, a.aid as qa_aid_&number,
    a.w5_intvw_date as w5_intvw_dt_adol&number, a.w1_bdate as w1_bdate_adol&number 
	/*take needed vars from analytic file and label according to which of the 2 AIDs from the pair the join is for*/ 
	from &sibsdata s  
	inner join analytic_exp_sibs a /* inner join, just keep rows where that AID appears in both datasets */ 
	on s.aid_&number = a.aid /* join of AID_1 or AID_2 in sibs data with AID in analytic file */ 
	where a.w1_race ne . and a.w1_sex ne . and a.w1_cog_ability ne . and a.w5_age ne . and 
	a.any_adol_mh ne . and a.w5_py_serious_injury ne . and a.w1_hispanic_ethnicity ne . and a.w1_ses ne . /* drop rows missing on needed study vars - so after the macro is ran for each AID,
																											 this will have required that the PAIR is non-missing on all these vars */ ; 
quit;
%mend; 

/* do this join for all the AID_1s */
%wide_join_sib_analytic(sibsdata=sibs, number=1); *n=1658, 17 columns; 

/* and all the AID_2s */ 
%wide_join_sib_analytic(sibsdata=widesib_analytic_1, number=2); *n=1031, 28 columns; 

proc freq data=widesib_analytic_2 order=freq; table sibcl4  / missing ; run; 

** These counts now reflect those with non-missing information on study vars (given inner join with analytic data); 
proc sql; 
	select count (distinct AID_1) as distinct_aid1, 
		   count (distinct AID_2) as distinct_aid2,
		   count (distinct pair) as distinct_pairs,
		   count (distinct famid) as distinct_families, 
		   count(*) as n_rows 
    from widesib_analytic_2; 
quit; 
run;

** Check # families in analytic file while excluding pairs with types not-included in analyses; 
proc sql; 
	select count (distinct AID_1) as distinct_aid1, 
		   count (distinct AID_2) as distinct_aid2,
		   count (distinct pair) as distinct_pairs,
		   count (distinct famid) as distinct_families, 
		   count(*) as n_rows 
    from widesib_analytic_2 (where=(sibcl4 ne "delete")); 
quit; 
run; *957 pairs from 878 families. This is replicated later in this script and reported in Methods text. ; 
	
proc print data=widesib_analytic_2 (obs=10); run; 
proc print data=widesib_analytic_2 (obs=5); where sibcl4="delete"; run;
proc print data=widesib_analytic_2 (obs=20); where sibcl4 in ("MZ", "DZ"); run; 

** Looking at within-sib correlations on vars - focus on the diagonal corr of adol1 w/ adol2 ; 
proc corr data=widesib_analytic_2; 
	var  inj_adol1 cog_adol1 int_adol1 ext_adol1 ses_adol1; 
	with inj_adol2 cog_adol2 int_adol2 ext_adol2 ses_adol2; 
run; 

/* How often does SES differ? */
proc sql;
	select count(*) from widesib_analytic_2
	where ses_adol1 ne ses_adol2 and sibcl4 ne "delete";   
	quit;
run; 

proc sql;
	select count(*) from widesib_analytic_2
	where sibcl4 ne "delete"; 
	quit;
run; 

/* What about by pair type? */ 
proc sql; 
	create table check as 
	select sibcl4, count(*) as count_pairs_vary_ses  
    from widesib_analytic_2 
	where ses_adol1 ne ses_adol2 and sibcl4 ne "delete" 
	group by sibcl4; 
	quit;
run; 

proc sql; 
	create table check2 as
	select sibcl4, count(*) as count_pairs
	from widesib_analytic_2
	where sibcl4 ne "delete"
	group by sibcl4;
	quit; 
run; 

proc sql;
	create table check3 as select *, 
	check.count_pairs_vary_ses/check2.count_pairs*100 as percent_vary_ses 
	from check 
	inner join check2 
	on check.sibcl4=check2.sibcl4;
	quit; 
run; 
proc print data=check3; run; 

proc sort data=widesib_analytic_2 out=widesib_analytic3; by sibcl4; run; 

proc corr data=widesib_analytic3; 
	var  inj_adol1 cog_adol1 int_adol1 ext_adol1 ses_adol1 w5_age_adol1; 
	with inj_adol2 cog_adol2 int_adol2 ext_adol2 ses_adol2 w5_age_adol2; 
	by sibcl4; 
run; 

** Zooming in on SES concordance to report in paper supplement. See "Socioeconomic Status" in Table S1; 
proc corr data=widesib_analytic3; 
	var  ses_adol1;
	with ses_adol2; 
	by sibcl4; 
	where sibcl4 ne "delete"; 
run; 

/* PREPARE SIBS DATA FOR SIBLING-COMPARISONS */ 

*** Moving to a data structure with 1 row per adolescent, joined with the analytic data, for conditional logistic regression.; 

** First, transpose sib pairs file to long-format. 1 row per unique adolescent/pair combination, dropping pair types not included 
   in analysis (sibcl4=delete). ; 

proc sort data=sibs out=sorted; by famid sibcl4 pair; run; 

data sorted2; 
	set sorted; 
	where sibcl4 ne "delete"; 
run; 

proc transpose data=sorted2 out= sibs_long (rename=(col1 = aid)); 
var aid_1 aid_2; 
by famid sibcl4 pair; 
run; 

data sibs_long; 
	set sibs_long (keep=aid famid pair sibcl4); 
run; 

proc sort data=sibs_long out=sibs_long_sorted; by famid aid pair; run; 

* Check Ns;  
proc sql; 
	select count (distinct aid) as distinct_aid, 
	count(distinct pair) as distinct_pair,
	count(distinct famid) as distinct_fams,
	count(*) as n_rows 
	from sibs_long; 
	quit;
run; 
* The # rows is exactly 2x # pairs, which is what we want - There's 1 row per adolescent's contribution to a pair.
  But, some adolescents are in multiple rows if they contribute to multiple pairs. ; 

* Record # pairs each adolescent is contributing to... ; 
proc sql; 
	create table qa_npairs as select 
	aid, count(*) as n_pairs from sibs_long 
	group by aid
	order by aid;
	quit; 
run; 
proc freq data=qa_npairs; table n_pairs /norow nocol nopercent; run; 

** Next, move to a data structure with 1 row per adolescent and columns indicating (potentially multiple) types of sibling relationships 
  for sibling pairs that the adolescent belongs to;
 
proc sort data=sibs_long; by aid; run; 
data count_pairs; 
	set sibs_long; 
	by aid; 
	if first.aid then pair_counter=0; 
	pair_counter +1; * create var indicating the number of pairs the adolescent in the given row (pair) is a part of ; 
run; 

* check; 
proc sort data=count_pairs out=count_pairs_sorted; by famid aid; run;
proc print data=count_pairs_sorted (obs=50); run; 

* Transpose from long to wide, moving a given adolescent's different sibcl4 indicators from being represented across rows 
  to being represented as columns within the same row; 
proc transpose data=count_pairs out=transp; 
	var sibcl4; * transpose the sibcl4 var ;  
	by aid famid; 
	id pair_counter; * use the pair counter var values to label the appropriate transposed columns ; 
					* note the order doesn't matter, it's just that we want to populate those columns; 
run; 

proc contents data=transp; run; 

* Label the columns, each of which indicate the sibling type for each pair an adolescent belongs to (up to 4, but usually just 1) 
--Note this will run in SAS but not SAS Enterprise Guide-- ; 
data sibs_analyses;  
	set transp (drop=_name_ _label_); 
	rename _1 = sib1; 
	rename _2 = sib2; 
	rename _3 = sib3; 
	rename _4 = sib4; 
run; 
 
proc sort data=sibs_analyses out=sorted_toprint; by famid aid; run; 
proc print data=sorted_toprint (obs=150); run;  

**Check - should have 5,426 rows in each of these datasets; 
proc contents data=qa_npairs; run; 
proc contents data=sibs_analyses; run; *Good; 

* Check: Join those datasets and verify that the n_pairs 
  var corresponds as expected with the sib indicators.; 

proc sql; 
	create table sibs_analyses2 as select * from sibs_analyses s
	left join qa_npairs q 
	on s.aid = q.aid
	order by famid, aid ;
	quit;
run;  

proc means data=sibs_analyses2 n min max mode median mean; var n_pairs; run; 
proc contents data=sibs_analyses2; run; 

** OUTPUT file of all sibs in starting sample, to use in Script #9b for investigating 
   characteristics of different samples while deriving informative sibling sample.; 
	data AHdata.starting_sibs; 
		set sibs_analyses2;
	run; 

*** Now join sibs data with analytic data - again, with the expanded file with n=12,300 all individuals 
followed to W5 even if missing design variables; 

proc contents data=sibs_analyses2; run; 
proc contents data=analytic_exp_sibs; run; 

** join; 
** left join (keep a row for all 5,426 in sib dataset) but note some people will be null on 
   all the analytic file info if there was no match found (as in, if the adolescent 
   was in the sibling sample but was not followed to wave V).
   Retain "analytic_aid," because if it's null that means the person wasn't in 
   the W5 data. ; 

proc sql; 
	create table sib_analytic as select s.*, a.any_adol_mh, a.ext_adol_mh, a.int_adol_mh,
	a.in_analytic, a.w1_race, a.w1_hispanic_ethnicity, a.w1_sex, a.w1_ses, a.w1_cog_ability, a.w5_age, 
	a.w5_any_inj_type, a.w5_py_serious_injury, a.w5_py_assault_inj, a.w5_py_suicide_attempt, 
	a.aid as analytic_aid 
	from sibs_analyses2 s
	left join analytic_exp_sibs a 
	on s.aid = a.aid
	order by famid, aid; 
	quit; 
run; *n=5,426; 

proc sql; 
	select count(*) as lost_sibs 
	from sib_analytic 
	where analytic_aid = ' '; 
quit;
run; *n=2,236 have null analytic AID.; 

data sib_analytic2; 
	set sib_analytic; 
	where analytic_aid is not missing; 
run; *so left with n=3,190 adolescents; 

** Also need to drop participant if they are the only sibling in their pair.; 

proc sql; 
	create table check_lost_sibs as select
	famid, count(*) as n_in_fam 
	from sib_analytic2 
	group by famid; 
quit; 

proc freq data=check_lost_sibs; table n_in_fam; run; 
* So among 2,088 families, 1,036 have only 1 participant represented.; 

* To double-check: Replicate this another way; 
proc sort data=sib_analytic2; by famid; run; 

data sib_analytic3; 
	set sib_analytic2; 
	by famid; 
	if first.famid then fam_member_count=0; 
	fam_member_count+1; 
run; 

* Flag "lone sibs" who were followed to Wave V without their sibling(s) ; 

proc sql; 
	create table flag_sibs as select *, 
	(max(fam_member_count)=1) as lone_sib /* if the highest the counter gets is 1, there's only 1 adolescent from the family present at Wave V */
	from sib_analytic3
	group by famid
	order by famid, aid; 
quit; 

** Then, also need to drop individuals who were followed to Wave V but either they or their sib(s) were missing info on study variables.; 
data flag_in_sib_analytic; 
	set flag_sibs; 
	in_sib_analytic = (any_adol_mh ne . and w5_py_serious_injury ne . and w1_race ne . and w5_age ne . 
					   and w1_sex ne . and w1_hispanic_ethnicity ne . and w1_cog_ability ne . and w1_ses ne .) ; 
					  **not requiring nonmissing info on suicide attempt, assault injury; 
run; 

proc sql; 
	create table flag_in_sib_analytic2 as select *, 
	(sum(in_sib_analytic)>1) as pair_in_sibanalytic /* if the sum is >1, there are at least 2 sibs from the family meeting inclusion criteria */ 
	from flag_in_sib_analytic
	group by famid 
	order by famid, aid; 
	quit;
run; 

proc freq data=flag_in_sib_analytic2; table lone_sib*pair_in_sibanalytic; run; 

** Since a family of 3+ sibs could have 2 with non-missing info but 1 without, also need to ensure that 
the participant themselves has information on study variables. So only keep rows where in_sib_analytic=1 as well as pair_in_sibanalytic=1.; 
data cleaned_sib_analytic; 
	set flag_in_sib_analytic2; 
	where pair_in_sibanalytic=1 and in_sib_analytic=1;
run; *N=1,796; 

** Check missingness; 
proc means n nmiss data=flag_sibs; var any_adol_mh w1_race w5_age w1_sex w1_hispanic_ethnicity w1_cog_ability w1_ses w5_py: ; run; 
proc means n nmiss data=cleaned_sib_analytic; var any_adol_mh w1_race w5_age w1_sex w1_hispanic_ethnicity w1_cog_ability w1_ses w5_py: ; run; 

proc contents data=cleaned_sib_analytic; run;

** Check counts of ptcpts and families;
proc sql;
	select count(*) as count_rows, count(distinct aid) as count_distinct_aid, count(distinct famid) as count_distinct_famid
	from cleaned_sib_analytic;
quit; *1796 rows, 1796 unique AIDs, 878 unique family IDs. This 878 replicates what was observed in wide-format data above.; 

*** OUTPUT the sibling analytic file for analysis. ; 
proc contents data=cleaned_sib_analytic; run; 

proc sort data=cleaned_sib_analytic; by famid aid; run; 

data AHdata.sibling_analytic; 
	set cleaned_sib_analytic; 
run; 

