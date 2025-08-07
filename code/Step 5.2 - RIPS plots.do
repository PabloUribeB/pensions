/*************************************************************************
 *************************************************************************			       	
               RIPS results plots

1) Created by: Pablo Uribe
               Yale University
               p.uribe@yale.edu

2) Date: July 9, 2025

3) Objective: Plot the health results
*************************************************************************
*************************************************************************/		
clear all

****************************************************************************
*		Global directory, parameters and assumptions:
****************************************************************************

set graphics off
set scheme white_tableau
cap mkdir "${graphs}/latest/RIPS/age"

****************************************************************************
**#              1. Call data and set labels
****************************************************************************

use "${output}\RIPS_results.dta", clear

** Might be temporary, fix eventually
append using "${output}/RIPS_results_rdhonest.dta", gen(o)
drop if o == 1 & (model == "rdrobust" | runvar == "std_days")
drop o

encode outcome, gen(en_outcome)
label def labout 1 "Cardiovascular" 2 "Chronic disease"                     ///
3 "Consultation with psychologist" 4 "Probability of consultation"          ///
5 "Mental diagnosis" 6 "Stress" 7 "Probability of hospitalization"          ///
8 "Infarct" 9 "Number of hospitalizations" 10 "Number of consultations"     ///
11 "Number of procedures" 12 "Number of services" 13 "Number of ER visits"  ///
14 "Multi-morbidity index" 15 "Probability of procedures"                   ///
16 "Probability of health service" 17 "Probability of ER visit"

label val en_outcome labout

****************************************************************************
**#              2. Plot age-level results
****************************************************************************

drop if (cohort == "F55" & inlist(age, 52, 66)) |                   ///
        (cohort == "M50" & inlist(age, 57, 71)) | mi(coef) | coef == 0


levelsof outcome, local(outcomes)
local outcome = 1
foreach variable in `outcomes'{

    local vallab : label (en_outcome) `outcome'
    scalar cut = 59.5
    
    foreach cohort in M50 F55{
            
        foreach model in rdrobust rdhonest {
            
            local ranges
            
            qui sum age if cohort == "`cohort'" & outcome == "`variable'"
            scalar min = r(min)
            scalar max = r(max)
            
            qui sum ci_upper if cohort == "`cohort'" & outcome == "`variable'"
            
            if substr("`variable'", 1, 3) == "nro" & r(max) < 0 {
                
                local ymax = 1 
                qui sum ci_lower if cohort == "`cohort'" & outcome == "`variable'"
                local ymin = round(r(min))
                local ranges "yscale(range(`ymin' `ymax'))"
                
            }
            
            else if substr("`variable'", 1, 3) != "nro" & r(max) < 0 {
                
                local ymax = 0.05 
                qui sum ci_lower if cohort == "`cohort'" & outcome == "`variable'"
                local ymin = round(r(min), .01)
                local ranges "yscale(range(`ymin' `ymax'))"
                
            }
            
            tw (rspike ci_lower ci_upper age, lcolor(ebblue) lp(solid))         ///
            (scatter coef age, mcolor(ebblue))                                  ///
            if (cohort == "`cohort'" & outcome == "`variable'" &                ///
            model == "`model'" & !mi(age)),                                     ///
            legend(position(bottom) rows(1) order(2 "Point estimate"            ///
            1 "95% confidence interval")) xline(`=cut', lcolor(gs7))            ///
            yline(0, lp(solid)) ytitle(`vallab')                                ///
            xlabel(`=min'(1)`=max') xtitle(Age)                                 ///
            ylabel(#10, format(%010.3fc) labs(vsmall)) `ranges'                 ///
            subtitle(Cohort: `cohort', size(medsmall))
    
            graph export "${graphs}/latest/RIPS/age/`variable'_`cohort'_`model'.png", replace
    
        }
        scalar cut = 54.5
    }
    local ++outcome
}


****************************************************************************
**#              3. Difference-in-discontinuities plots
****************************************************************************

use "${output}/RIPS_results_diffdisc.dta", clear

encode outcome, gen(en_outcome)

gen extensive = (substr(outcome, 1, 3) != "nro")

bysort cohort extensive: gen counter = _n

foreach cohort in M50 F55 {
        
    * Extensive margin
    tw (bar coef counter, barwidth(0.7))                                    ///
    (rcap ci_lower ci_upper counter)                                        ///
    if cohort == "`cohort'" & substr(outcome, 1, 3) != "nro",               ///
    legend(position(bottom) rows(1) order(1 "Point estimate"                ///
    2 "95% confidence interval"))                                           ///
    yline(0, lpattern(solid) lcolor(black)) xtitle(Variable)                ///
    subtitle(Cohort `cohort')                                               ///
    xlabel(1 "Cardiovascular" 2 `""Chronic" "disease""'                     ///
    3 `""Consultation" "with" "psychologist""'                                ///
    4 `""Probability" "of consultation""' 5 `""Mental" "diagnosis""'        ///
    6 "Stress" 7 `""Probability" "of hospitalization""' 8 "Infarct"         ///
    9 `""Probability" "of procedures""' 10  `""Probability" "of ER visit""', labs(vsmall))
    
    graph export "${graphs}/latest/RIPS/DiffD_`cohort'_ext.png", replace
    
    
    * Intensive margin
    tw (bar coef counter, barwidth(0.7))                                 ///
    (rcap ci_lower ci_upper counter)                                     ///
    if cohort == "`cohort'" & substr(outcome, 1, 3) == "nro",               ///
    legend(position(bottom) rows(1) order(1 "Point estimate"                ///
    2 "95% confidence interval"))                                           ///
    yline(0, lpattern(solid) lcolor(black)) xtitle(Variable)                ///
    subtitle(Cohort `cohort')                                               ///
    xlabel(1 "Hospitalizations" 2 "Consultations" 3 "Procedures"            ///
    4 "Services" 5 "ER visits")
    
    graph export "${graphs}/latest/RIPS/DiffD_`cohort'_int.png", replace

}

