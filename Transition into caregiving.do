
* Section 1: Sample restrictions, waves 1,2,3,4,6
* Section 2: Variable construction, waves 1,2,3,4,6
* Section 3: Sample restrictions, waves 4,6
* Section 4: Wide data preparation, waves 4,6
* Section 5: Descriptive statistics, waves 4,6
* Section 6: OLS estimation, waves 4,6
* Section 7: Propensity Score Matching, waves 4,6
* Section 8: Instrumental variable assesment, waves 4,6
* Section 9: Difference in Differences, waves 4,6
* Section 10: Difference in Differences parallel trends, waves 1,2,3,4,6

* Missing observations are dropped on a method-specific basis, only for variables required by each empirical specification.

* Load raw UKHLS data provided for research project
use "/Users/Elliot/UKHLS Waves 2-9.dta", clear

* UKHLS waves 2-9 correspond to waves 1-8 within the dataset

* Throughout this project, all references to wave numbers refer to internal coding, not the original UKHLS wave numbers. 

* Variable definitions
describe


** Section 1: Sample restrictions waves 1, 2, 3, 4, 6
 

keep if inlist(wave,1,2,3,4,6)
tab wave

* Variable removal

* The analysis will use gross monthly personal income as income measure 
drop fimnlabgrs_dv fimnnet_dv

* Full or part-time employee only applies to employees not the full sample
drop jbft_dv

* Hours worked per week does not apply to the full sample
drop jbhrs

* Convert negative survey codes to missing
local vars sex dvage istrtdaty istrtdatm istrtdatd jbstat racel_dv health aidhh aidxhh  sclfsato gor_dv mastat_dv nchild_dv hiqual_dv scghq1_dv scghq2_dv 
foreach v of local vars {
    replace `v' = . if `v' < 0
}

* Ensuring gross personal income is strictly positive
replace fimngrs_dv=. if fimngrs_dv<=0


** Section 2: Variable construction waves 1, 2, 3, 4, 6


* Dependent variable GHQ likert
tab scghq1_dv
gen ReverseLikertGHQ = 36 - scghq1_dv
label var ReverseLikertGHQ "Reverse GHQ Likert (Ascending Well-being)"

* Carer
recode aidhh (1 = 1 "yes cares in HH") (2=0 "no care in HH"), gen(carehh)
recode aidxhh (1 = 1 "yes cares outside HH") (2=0 "no care outside HH"), gen(carexhh)

gen Carer = .
replace Carer = 1 if carehh==1 | carexhh==1
replace Carer = 0 if carehh==0 & carexhh==0
label var Carer "1 if provides informal care in household or out of household"

* Age and age squared
rename dvage Age
label var Age "age from date of birth"
gen AgeSquared = (Age)^2
label var AgeSquared "age from date of birth squared"

* Gender
gen Male = .
replace Male = 1 if sex==1
replace Male = 0 if sex==2
label var Male "1 if male"

* Long standing illness or disability
recode health (1=1 "yes") (2=0 "no"), gen(Impairment)
label var Impairment "1 if long standing illness or disability"

* Married or cohabitation
recode mastat_dv (2 3 10 = 1 "married or cohabitation") (1 4 5 6 7 8 9 =0 "not married or cohabitation"), gen(MarriedCohabitation)
label var MarriedCohabitation "1 if married or cohabiting"

* Education
gen Degree = (hiqual_dv ==1 | hiqual_dv ==2) if hiqual_dv<.
gen Alevel = hiqual_dv==3 if hiqual_dv<.
gen GCSE = hiqual_dv==4 if hiqual_dv<.

label variable GCSE "1 if highest qualification is GCSE"
label variable Alevel "1 if highest qualification is A Level"
label variable Degree "1 if highest qualification is undergraduate degree or postgraduate degree"

* Log transformation of monthly gross personal income
gen LnGrossIncome = log(fimngrs_dv)
label var LnGrossIncome "Log transformation of total monthly personal income"

* Economic activity
recode jbstat (1=1 "self employed") (2=2 "paid employment") (3=3 "unemployed")(4/11 97=4 "Economically inactive"), gen(JobStatus)
label var JobStatus "Current economic activity"

* Number of children in household
rename nchild_dv Children

* British
gen British = .
replace British = 1 if racel_dv ==1
replace British = 0 if racel_dv <. & racel_dv !=1
label var British "1 if British"

* Region
rename gor_dv Region

* Reordering 
order pidp, after(scghq2_dv)
order wave, after(pidp)
order carehh, after(scghq2_dv)
order carexhh, after(carehh)
order Age, after(Carer)
order Region, after(British)
order Children, after(Region)

* restricted dataset to variables required for empirical analysis
keep wave pidp ReverseLikertGHQ Carer Age AgeSquared Male Impairment MarriedCohabitation Degree Alevel GCSE LnGrossIncome JobStatus British Region Children

* Save cleaned data for waves 1, 2, 3, 4, 6 will be reused in DiD parallel trends
save "/Users/Elliot/Waves_1_2_3_4_6_long.dta", replace


** Section 3: Sample restrictions waves 4, 6 


* Restrict sample to waves 4 and 6
keep if inlist(wave,4,6)

* Drop missing for key variables
drop if missing(pidp, wave, ReverseLikertGHQ, Carer)

* Two wave balanced panel 
bysort pidp: gen T=_N
keep if T==2
drop T

* Declaring data is panel data
xtset pidp wave

* Ensuring time-invariant variables to be constant
sort pidp wave
by pidp (wave): replace Male = Male[1] if Male < .  
by pidp (wave): replace British = British[1] if British < .

* Exclude carers in the pre-treatment wave, but keep both waves
bysort pidp: egen CarerW4 = max(Carer==1 & wave==4)
keep if CarerW4==0
drop CarerW4

* Save cleaned long data for waves 4, 6 that will be reused in DiD 
save "/Users/Elliot/Waves_4_6_long.dta", replace


* Section 4: wide dataset preparation waves 4, 6 

* Declaring data is panel data
xtset pidp wave

* Convert from long to wide dataset
reshape wide ReverseLikertGHQ Carer Age AgeSquared Male Impairment MarriedCohabitation Degree Alevel GCSE LnGrossIncome JobStatus British Region Children, i(pidp) j(wave)

* Drop missing values for Section 5, 6, and 7 empirical analysis
drop if missing(ReverseLikertGHQ6, Carer6, Male4, Age4,LnGrossIncome4, Impairment4, MarriedCohabitation4, Degree4, Alevel4, GCSE4, Children4, British4, Region4, JobStatus4)


** Section 5: Preliminary analysis waves 4, 6 


* Descriptive statistics wave 4 covariates
tabstat ReverseLikertGHQ4 Age4 Male4 LnGrossIncome4 Impairment4 MarriedCohabitation4 Degree4 Children4 British4, by(Carer6) statistics(mean sd)columns(statistics)	
	
* Comparison of means and comparison of means test
mean ReverseLikertGHQ6, over(Carer6)
ttest ReverseLikertGHQ6, by(Carer6) reverse unequal


** Section 6: OLS estimation waves 4, 6 


* Naive OLS regression
regress ReverseLikertGHQ6 Carer6, robust
estimates store NaiveOLS

* OLS regression with control variables
reg ReverseLikertGHQ6 Carer6 Male4 c.Age4##c.Age4 LnGrossIncome4 Impairment4 MarriedCohabitation4 Degree4 Alevel4 GCSE4 Children4 British4 i.Region4 i.JobStatus4, robust
estimates store ControlsOLS

* Appendix C output
esttab NaiveOLS using workshop5.rtf, replace star(* 0.1 ** 0.05 *** 0.01) se mtitles r2 obslast compress 
esttab ControlsOLS using workshop5.rtf, replace star(* 0.1 ** 0.05 *** 0.01) se mtitles r2 obslast compress 


** Section 7: Propensity Score Matching waves 4, 6 


* Estimate the propensity scores using a logit model
logit Carer6 Male4 c.Age4##c.Age4 LnGrossIncome4 Impairment4 MarriedCohabitation4 Degree4 Alevel4 GCSE4 Children4 British4 i.Region4 i.JobStatus4
predict pslogit, pr

* Overlap check 
sum pslogit if Carer6==1
sum pslogit if Carer6==0

* Visual inspection of before matching overlap plot
twoway (kdensity pslogit if Carer6==1, lcolor(black) lpattern(solid)) (kdensity pslogit if Carer6==0, lcolor(black)  lpattern(dash)), legend(order(1 "Carers" 2 "Non-carers")) title("Propensity Score Overlap Before Matching") xtitle("Propensity Score") ytitle("Density")

* Estimate ATT using nearest neighbour PSM
* Default propensity score model is logit
teffects psmatch (ReverseLikertGHQ6) (Carer6 Male4 c.Age4##c.Age4 LnGrossIncome4 Impairment4 MarriedCohabitation4 Degree4 Alevel4 GCSE4 Children4 British4 i.Region4 i.JobStatus4), atet

* Covariate balance
tebalance summarize Male4 c.Age4##c.Age4 LnGrossIncome4 Impairment4 MarriedCohabitation4 Degree4 Alevel4 GCSE4 Children4 British4 i.Region4 i.JobStatus4

* Probit propensity score model robustness check 
teffects psmatch (ReverseLikertGHQ6) (Carer6 Male4 c.Age4##c.Age4 LnGrossIncome4 Impairment4 MarriedCohabitation4 Degree4 Alevel4 GCSE4 Children4 British4 i.Region4 i.JobStatus4, probit), atet


** Section 8: Instrumental variable assessment waves 4, 6 


* Objective: Evaluate whether a credible instrumental variables (IV) strategy exists for identifying the causal effect of becoming a carer on subjective well-being (reverse GHQ Likert).

* IV requirements:
* Z predicts Carer6 (empirical)
* Z affects subjective well-being only through Caregiving (theoretical)

* Candidate 1: Number of children (Children4)
reg Carer6 Children4 Male4 c.Age4##c.Age4 LnGrossIncome4 Impairment4 MarriedCohabitation4 Degree4 Alevel4 GCSE4 British4 i.Region4 i.JobStatus4, robust
test Children4
* Children4 does not provide strong evidence of relevance in this specification

* Candidate 2: Age (Age4)
reg Carer6 c.Age4##c.Age4 Male4 Children4 LnGrossIncome4 Impairment4 MarriedCohabitation4 Degree4 Alevel4 GCSE4 British4 i.Region4 i.JobStatus4, robust
test Age4
* Age provides evidence of relevance in this specification

* Although age predicts caregiving status, the exclusion restriction fails. Age plausibly affects subjective well-being through health, life-cycle factors, and labour market attachment, independent of caregiving.

* Diagnostic 2SLS (not used for inference)
ivregress 2sls ReverseLikertGHQ6 Male4 LnGrossIncome4 Impairment4 MarriedCohabitation4 Degree4 Alevel4 GCSE4 Children4 British4 i.Region4 i.JobStatus4 (Carer6 = Age4), first robust

* Conclusion: Given the absence of any variable that plausibly satisfies both the relevance and exclusion restrictions, no further IV candidates are considered

	
** Section 9: Difference in Differences waves 4, 6 


* Manual step for replication
* The dataset required is saved as the final command of section 3

use "/Users/Elliot/Waves_4_6_long.dta", clear 

drop if missing(pidp, wave, ReverseLikertGHQ, Carer)

* Declare panel structure
xtset pidp wave

* Define treatment group explicitly: new carers (0 in wave 4, 1 in wave 6)
bysort pidp: egen CarerW4 = max(Carer==1 & wave==4)
bysort pidp: egen CarerW6 = max(Carer==1 & wave==6)

gen Treatment = CarerW6==1
label var Treatment "1 if enters caregiving between wave 4 and wave 6"
* Note: sample excludes wave-4 carers in Section 3, so Treatment identifies entry by wave 6.

* Post indicator (wave 6)
gen Post = (wave==6)
label var Post "1 if wave 6"

* Diagnostics
tab CarerW4 CarerW6
tab Treatment

* Main DiD, POLS interaction, clustered standard errors
reg ReverseLikertGHQ i.Treatment##i.Post, vce(cluster pidp)
estimates store TwoWaveDiD

* Construct baseline (wave 4) covariates explicitly
local vars Male Age LnGrossIncome Impairment MarriedCohabitation Degree Alevel GCSE Children British Region JobStatus

sort pidp wave
foreach v of local vars {
    gen `v'_pre = `v' if wave==4
    by pidp: egen `v'_pre2 = max(`v'_pre)
    drop `v'_pre
    rename `v'_pre2 `v'_pre
}

* DiD with covariates, clustered standard errors
reg ReverseLikertGHQ i.Treatment##i.Post Male_pre c.Age_pre##c.Age_pre LnGrossIncome_pre Impairment_pre MarriedCohabitation_pre Degree_pre Alevel_pre GCSE_pre Children_pre British_pre i.Region_pre i.JobStatus_pre , vce(cluster pidp)
estimates store TwoWaveControlsDiD

* Appendix C output	
esttab TwoWaveDiD using workshop5.rtf, replace star(* 0.1 ** 0.05 *** 0.01) se mtitles r2 obslast compress 	
esttab TwoWaveControlsDiD using workshop5.rtf, replace star(* 0.1 ** 0.05 *** 0.01) se mtitles r2 obslast compress 	
	
	
** Section 10: Difference in Differences parallel trends 
* waves 1, 2, 3, 4 pre treatment, wave 6 treatment


* Manual step for replication
* The dataset required is saved as the final command of section 2

use "/Users/Elliot/Waves_1_2_3_4_6_long.dta", clear 

drop if missing(pidp, wave, ReverseLikertGHQ, Carer)

* Balanced panel 
bysort pidp: gen T=_N
keep if T==5
drop T

* Declaring data is panel data
xtset pidp wave

* Exclude carers in pre-treatment waves (1-4)
gen PreCarer = (Carer==1 & inlist(wave,1,2,3,4))
bysort pidp: egen EverPre = max(PreCarer)
keep if EverPre == 0
drop PreCarer EverPre

* Treatment indicator: equals 1 only in treatment wave for those who enter caring at wave 6
gen CarerWave6 = (Carer==1 & wave==6)

* DiD estimator 
xtdidregress (ReverseLikertGHQ) (CarerWave6), group(pidp) time(wave)
estimates store PreWavesDiD

* Visualisation of trends before treatment
estat trendplots

* Parallel trends test
estat ptrends

* Appendix C output
esttab PreWavesDiD using workshop5.rtf, replace star(* 0.1 ** 0.05 *** 0.01) se mtitles r2 obslast compress 
