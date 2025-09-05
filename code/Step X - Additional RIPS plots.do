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
cap mkdir "${graphs}/latest/RIPS/age/new"

****************************************************************************
**#              1. Call data and set labels
****************************************************************************

use "${output}\RIPS_results_new.dta", clear

encode outcome, gen(en_outcome)
label def labout 1 "Work accident" 2 "Anxiety"                     ///
3 "Consultation with mental prof." 4 "Consultation with psychologist"          ///
5 "Consultation with psychiatrist" 6 "Consultation with social worker" 7 "Depression"          ///
8 "Work diagnosis" 9 "Mental diagnosis" 10 "SAD diagnosis"     ///
11 "Work illness" 12 "Work stress" 13 "Hypertension"  ///
14 "Musculoskeletal disease"

label val en_outcome labout

****************************************************************************
**#              2. Plot age-level results
****************************************************************************

drop if (cohort == "F55" & inlist(age, 52, 66)) |                   ///
        (cohort == "M50" & inlist(age, 57, 71)) | mi(coef) | coef == 0

drop if en_outcome == 12 & ((age > 62 & cohort == "M50") | (age > 57 & cohort == "F55"))


gen     bw = string(h_l)
replace bw = "one" if !inlist(h_l, 10, 21, 42) & h_l == h_r
replace bw = "two" if !inlist(h_l, 10, 21, 42) & h_l != h_r
        
gen ci_l90 = coef - stderr*1.645
gen ci_u90 = coef + stderr*1.645
        
levelsof outcome, local(outcomes)
local outcome = 1
foreach variable in `outcomes'{

    local vallab : label (en_outcome) `outcome'
    scalar cut = 59.5
    
    foreach cohort in M50 F55{
            
        foreach bw in one two {
            
            qui sum ci_lower if cohort == "`cohort'" & outcome == "`variable'" & model == "rdrobust"
            local ymin = round(r(min),0.01)
            
            qui sum ci_upper if cohort == "`cohort'" & outcome == "`variable'" & model == "rdrobust"
            local ymax = round(r(max),0.01)
            
            qui sum age if cohort == "`cohort'" & outcome == "`variable'" & bw == "`bw'"
            scalar min = r(min)
            scalar max = r(max)
            
            if substr("`variable'", 1, 3) != "nro" & r(max) < 0 {
                
                local ymax = 0.05 
                qui sum ci_lower if cohort == "`cohort'" &              ///
                        outcome == "`variable'" & model == "rdrobust" & bw == "`bw'"
                        
                local ymin = round(r(min), .01)
                
            }
            
            tw (rcap ci_lower ci_upper age, lcolor(ebblue) lp(solid))           ///
            (rcap ci_l90 ci_u90 age, lcolor(maroon) lp(solid))                  ///
            (scatter coef age, mcolor(black))                                   ///          
            if (cohort == "`cohort'" & outcome == "`variable'" &                ///
            model == "rdrobust" & !mi(age) & bw == "`bw'"),                     ///
            legend(position(bottom) rows(1) order(3 "Point estimate"            ///
            1 "95% confidence interval" 2 "90% confidence interval"))           ///
            xline(`=cut', lcolor(gs7)) yline(0, lp(solid)) ytitle(`vallab')     ///
            xlabel(`=min'(1)`=max') xtitle(Age)                                 ///
            ylabel(#7, format(%010.3fc) labs(vsmall)) yscale(range(`ymin' `ymax'))                 ///
            subtitle(Cohort: `cohort', size(medsmall))
    
            graph export "${graphs}/latest/RIPS/age/new/`variable'_`cohort'_`bw'.png", replace
    
        }
        scalar cut = 54.5
    }
    local ++outcome
}
