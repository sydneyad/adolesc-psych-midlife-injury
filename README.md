# Adolecent Psychopathology and Risk of Injuries in Early Midlife: Evidence from a Nationally-Representative Cohort Study 

## Project Abstract 

Psychopathology is associated with physical injury, but research has largely concerned intentional self-injury, individual mental-health conditions, and childhood injuries. In a U.S. cohort (N=10,363), we tested whether adolescents with psychopathology were more likely to experience injuries and circumstances complicating injury recovery in early midlife. Adolescents with psychopathology had elevated risk of midlife assault injury (OR=2.99 [2.23-3.99]) and unintentional injury (OR=1.41 [1.18-1.67]), in addition to intentional self-injury (OR=2.49 [1.60-3.87]), after accounting for demographics, adolescent socioeconomic status, and adolescent cognitive ability. Associations with assault and unintentional injury were evident for internalizing and externalizing psychopathology. Siblings with psychopathology were not more likely to experience unintentional injury than their co-siblings without psychopathology, but estimates were imprecise and informed by few families. Adolescents with psychopathology were more likely to experience fair-to-poor self-rated health, low social support, unemployment, lack of health insurance, and unmet healthcare need in midlife. Supporting adolescents’ mental health may prevent midlife injuries.
 
## Table of Contents

### 1_Identifying_weights_designvars.sas
- Reads-in the Wave V complex survey design variables and flags participants for whom they are missing 
### 2_Defining_covariates.sas
- Reads-in data from Waves I and V, as well as the constructed SES data, and creates indicators of the study covariates (Wave V age, sex, race, ethnicity, SES, cognitive ability) 
### 3_Defining_adol_psych_predictors.sas
- Reads-in data from Waves I, II, IV, and V and creates indicators of any, internalizing, and externalizing psychopathology during adolescence. 
### 4_Defining_outcomes.sas
- Reads-in data from Wave V and creates indicators of the injury and midlife contextual circumstance outcomes. 
### 5_Identifying_analytic_sample.sas
- Reads-in datasets created in scripts #1-4, joins them together to generate an analytic dataset with N=10,363 participants flagged as being in the analytic sample. See Figure S1. 
### 6_Descriptives_and_Aims_1_2.sas
- Generates sample characteristics, cross-tabulations of adolescent psychopathology and midlife injury outcomes, and demographic-adjusted estimates of the associations of (any, internalizing, and externalizing) adolescent psychopathology with the midlife injury outcomes. See Table 1, Table 2, and Figure 1.  
### 7_Aim3a_adjusted_models.sas
- Generates fully-adjusted estimates of the associations of (any, internalizing, and externalizing) adoelscent psychopathology with the midlife injury outcomes. See Table 2. 
### 8_Aim3b_sibling_comparison_prep_qa.sas
- Reads-in the Add Health sibling pairs data file and joins it with information on the study analytic variables. Identifies the sibling-comparison sample. See Figure S2. 
### 9_Aim3b_sib_comparison_analyses.sas
- Generates sample descriptives, cross-tabulations of psychopathology with injury, sample-wide associations, and sibling-comparison associations of psychopathology with injury in the sibling-comparison sample. See Results text.  
### 9b_Aim3b_sib_comparing_samples_expl_attrition.sas
- Examines sample characteristics for the starting and analytic samples, for both the overall study sample and the sibling-comparison sample. See Table S3. 
### 10_Aim4_midlife_circumstance_models.sas
- Generates descriptive statistics, demographic-adjusted associations, and fully-adjusted associations for the analyses of psychopathology and difficult midlife circumstances. See Figure 2 and Table S4. 
### 11_Sensitivity_analyses.sas
-  Runs various secondary and sensitivity analyses testing alternate variable definitions and cohorts. See Table S5 and Table S6.
### 12_Secondary_cumulative_injuries_prep.sas
- Reads-in data from the study analytic file and the Add Health waves I, II, and IV, to create an indicator of accumulating reports of injury across waves. Prepares a CSV file for analysis of this secondary outcome in M-Plus. See "Cumulative Injury Reports Across Waves" row in Table S1. 
### 13_Sec_count_inj_waves_neg_binom_analysis_ANY-ADJ.inp 
- An M-Plus file running an adjusted negative binomial regression analysis of any adolescent psychopathology and cumulative reports of past-year injury through midlife. See Table S6. 
### 14_Sec_count_inj_waves_neg_binom_analysis_INT-ADJ.inp
- An M-Plus file running an adjusted negative binomial regression analysis of internalizing adolescent psychopathology and cumulative reports of past-year injury through midlife. See Table S6. 
### 15_Sec_count_inj_waves_neg_binom_analysis_EXT-ADJ.inp 
- An M-Plus file running an adjusted negative binomial regression analysis of externalizing adolescent psychopathology and cumulative reports of past-year injury through midlife. See Table S6. 

## Authors
### Code Authors
Sydney M. Adams, Kallisse R. Dent, Leah S. Richmond-Rakerd 
### Manucript Authors 
Sydney M. Adams, Kallisse R. Dent, Lara Khalifeh, Leah S. Richmond-Rakerd 

## Acknowledgements 
This research uses data from Add Health, funded by grant P01 HD31921 (Harris) from the Eunice Kennedy Shriver National Institute of Child Health and Human Development (NICHD), with cooperative funding from 23 other federal agencies and foundations. Add Health is currently directed by Robert A. Hummer and funded by the National Institute on Aging cooperative agreements U01, AG071448 (Hummer) and U01AG071450 (Aiello and Hummer) at the University of North Carolina at Chapel Hill. Add Health was designed by J. Richard Udry, Peter S. Bearman, and Kathleen Mullan Harris at the University of North Carolina at Chapel Hill. No direct support was received from grant P01-HD31921 for this analysis. 
Additionally, we thank Luke Hyde for his helpful comments on a draft of the study manuscript.
