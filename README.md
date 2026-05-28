# Adolecent Psychopathology and Risk of Injuries in Early Midlife: Evidence from a Nationally-Representative Cohort Study 

## Project Abstract 

**Purpose:** Psychopathology is associated with physical injury, but research has largely focused on intentional self-injuries, individual mental-health conditions, and injuries sustained during childhood. It remains unclear whether (a) psychopathology is associated with unintentional injury, (b) associations are evident for both internalizing and externalizing conditions, and (c) associations extend into early midlife. Additionally, individuals with a history of psychopathology may be more likely to experience injury-complicating contextual circumstances, but these have not yet been explored.  
**Methods:** This cohort study tested whether adolescents with psychopathology were more likely to experience injuries and circumstances complicating injury recovery in early midlife. Participants (N=10,363) were from the National Longitudinal Study of Adolescent to Adult Health. Adolescent psychopathology was measured using prospectively-reported symptoms and retrospectively-reported diagnoses. Past-year injuries and injury-complicating circumstances were self-reported at midlife. 
**Results:** Adolescents with psychopathology had elevated risk of midlife assault injury (OR=2.99 [2.23-3.99]) and unintentional injury (OR=1.41 [1.18-1.67]), in addition to suicide attempt;  OR=2.49 [1.60-3.87]),    after accounting for demographics, adolescent socioeconomic status, and adolescent cognitive ability. Associations with assault injury and unintentional injury were evident for both internalizing and externalizing psychopathology. Adolescents with psychopathology were more likely to experience midlife circumstances complicating injury recovery, including fair-to-poor self-rated health, low social support, unemployment, lack of health insurance, and unmet healthcare need. 
**Conclusion:** These findings identify adolescent psychopathology as an indicator of risk for early-midlife injury and support the integration of injury-prevention efforts with mental-health care. These efforts should consider multiple types of mental-health concerns, injury causes, and contextual circumstances. 

 
## Table of Contents

### 01_Identifying_weights_designvars.sas
- Reads-in the Wave V complex survey design variables and flags participants for whom they are missing.
### 02_Defining_covariates.sas
- Reads-in data from Waves I and V, as well as the constructed SES data, and creates indicators of the study covariates.
### 03_Defining_adol_psych_predictors.sas
- Reads-in data from Waves I, II, IV, and V and creates indicators of any, internalizing, and externalizing psychopathology during adolescence. 
### 04_Defining_outcomes.sas
- Reads-in data from Wave V and creates indicators of the injury and midlife contextual circumstance outcomes.
### 05_Identifying_analytic_sample.sas
- Reads-in datasets created in scripts #1-4, joins them together to generate an analytic dataset with N=10,363 participants flagged as being in the analytic sample. See Figure S1. 
### 06_Descriptives_and_Aims_1_2.sas
- Generates sample characteristics, cross-tabulations of adolescent psychopathology and midlife injury outcomes, and demographic-adjusted estimates of the associations of (any, internalizing, and externalizing) adolescent psychopathology with the midlife injury outcomes. See Table 1, Table 2, and Figure 1.  
### 07_Aim3a_adjusted_models.sas
- Generates fully-adjusted estimates of the associations of (any, internalizing, and externalizing) adoelscent psychopathology with the midlife injury outcomes. See Table 2. 
### 08_Aim3b_sibling_comparison_prep_qa.sas
- In preparation for a secondary sibling-comparison analysis, reads-in the Add Health sibling pairs data file and joins it with information on the study analytic variables. Identifies the sibling-comparison sample. See Table S3 and Figure S2. 
### 09_Aim3b_sib_comparison_analyses.sas
- Generates sample descriptives, cross-tabulations of psychopathology with injury, sample-wide associations, and sibling-comparison associations of psychopathology with injury in the sibling-comparison sample. See Table S3.  
### 09b_Aim3b_sib_comparing_samples_expl_attrition.sas
- Examines sample characteristics for the starting and analytic samples, for both the overall study sample and the sibling-comparison sample. See Table S4. 
### 10_Aim4_midlife_circumstance_models.sas
- Generates descriptive statistics, demographic-adjusted associations, and fully-adjusted associations for the analyses of psychopathology and difficult midlife circumstances. See Figure 2 and Table S5. 
### 11_Sensitivity_analyses.sas
-  Runs various secondary and sensitivity analyses testing alternate variable definitions and cohorts. See Table S6 and Table S7.
### 12_Secondary_cumulative_injuries_prep.sas
- Reads-in data from the study analytic file and the Add Health waves I, II, and IV, to create an indicator of accumulating reports of injury across waves. Prepares a CSV file for analysis of this secondary outcome in M-Plus. See "Cumulative Injury Reports Across Waves" row in Table S1. 
### 13_Sec_count_inj_waves_neg_binom_analysis_ANY-ADJ.inp 
- An M-Plus file running a negative binomial regression analysis of any adolescent psychopathology and cumulative reports of past-year injury through midlife. See Table S7. 
### 14_Sec_count_inj_waves_neg_binom_analysis_INT-ADJ.inp
- An M-Plus file running a negative binomial regression analysis of internalizing adolescent psychopathology and cumulative reports of past-year injury through midlife. See Table S7. 
### 15_Sec_count_inj_waves_neg_binom_analysis_EXT-ADJ.inp 
- An M-Plus file running a negative binomial regression analysis of externalizing adolescent psychopathology and cumulative reports of past-year injury through midlife. See Table S7. 

## Authors
### Manucript Authors 
Sydney M. Adams, Kallisse R. Dent, Lara Khalifeh, Leah S. Richmond-Rakerd 
### Code Authors
Sydney M. Adams, Kallisse R. Dent, Leah S. Richmond-Rakerd 

## Acknowledgements 
This research uses data from Add Health, funded by grant P01-HD31921 (Harris) from the Eunice Kennedy Shriver National Institute of Child Health and Human Development (NICHD), with cooperative funding from 23 other federal agencies and foundations. Add Health is currently directed by Robert A. Hummer and funded by the National Institute on Aging cooperative agreements U01-AG071448 (Hummer) and U01-AG071450 (Aiello and Hummer) at the University of North Carolina at Chapel Hill. Add Health was designed by J. Richard Udry, Peter S. Bearman, and Kathleen Mullan Harris at the University of North Carolina at Chapel Hill. No direct support was received from grant P01-HD31921 for this analysis. 
Additionally, we thank Luke Hyde for his helpful comments on a draft of the study manuscript.
