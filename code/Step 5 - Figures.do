/*************************************************************************
 *************************************************************************			       	
               Paper results plots

1) Created by: Pablo Uribe
               Yale University
               p.uribe@yale.edu

2) Date: September 5, 2025

3) Objective: Plot the draft results and save as pdf
*************************************************************************
*************************************************************************/
clear all

****************************************************************************
*		Global directory, parameters and assumptions:
****************************************************************************

set graphics off
set scheme white_tableau
cap mkdir "${graphs}/latest/RIPS/age"
cap mkdir "${graphs}/latest/PILA/age"
cap mkdir "${graphs}/latest/PILA/time"


****************************************************************************
**#                             RIPS
****************************************************************************

** 1. Call data and set labels

use "${output}\RIPS_results.dta", clear

keep if inlist(outcome, "cardiovascular", "nro_servicios", "nro_procedimientos")

append using "${output}/RIPS_results_new.dta", gen(o)

keep if o == 0 | (o == 1 & inlist(outcome, "msk", "estres_laboral"))
drop o

encode outcome, gen(en_outcome)
label def labout 1 "Cardiovascular" 2 "Work-related stress"                 ///
3 "Musculoskeletal illness" 4 "Number of procedures" 5 "Number of services"

label val en_outcome labout


** 2. Plot age-level results

drop if (cohort == "F55" & inlist(age, 52, 66)) |                   ///
        (cohort == "M50" & inlist(age, 57, 71)) | mi(coef) | coef == 0
        
drop if en_outcome == 2 & ((age > 62 & cohort == "M50") | (age > 57 & cohort == "F55"))
        
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
    
    if substr("`variable'", 1, 3) == "nro" local rounded = 0
    else                                   local rounded = 0.01
    
    foreach cohort in M50 F55{
            
        foreach bw in one two {
            
            qui sum ci_lower if outcome == "`variable'" & model == "rdrobust" & bw == "`bw'"
            local ymin = round(r(min), `rounded')
            
            qui sum ci_upper if outcome == "`variable'" & model == "rdrobust" & bw == "`bw'"
            local ymax = round(r(max), `rounded')
            
            qui sum age if cohort == "`cohort'" & outcome == "`variable'" & bw == "`bw'"
            scalar min = r(min)
            scalar max = r(max)
                        
            if substr("`variable'", 1, 3) == "nro" & r(max) < 0 {
                
                local ymax = 1 
                qui sum ci_lower if cohort == "`cohort'" &              ///
                        outcome == "`variable'" & model == "rdrobust" & bw == "`bw'"
                
                local ymin = round(r(min))
                
            }
            
            else if substr("`variable'", 1, 3) != "nro" & r(max) < 0 {
                
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
            ylabel(#7, format(%010.3fc) labs(vsmall)) yscale(range(`ymin' `ymax'))
    
            graph export "${graphs}/latest/RIPS/age/`variable'_`cohort'_`bw'.pdf", replace
    
        }
        scalar cut = 54.5
    }
    local ++outcome
}


****************************************************************************
**#                             PILA
****************************************************************************

** 1. Call data and set labels

use "${output}/PILA_results.dta", clear

** Might be temporary, fix eventually
drop if mi(coef_rb)
drop year month
keep if outcome == "pension_ibc"

encode outcome, gen(en_outcome)
label def labout 1 "Pension proxy with IBC"
label val en_outcome labout


** 3. Plot age-level results

drop if (cohort == "F55" & inlist(age, 52, 66)) |       ///
        (cohort == "M50" & inlist(age, 57, 71))

gen ci_l90 = coef - stderr*1.645
gen ci_u90 = coef + stderr*1.645
        
levelsof outcome, local(outcomes)
local outcome = 1
foreach variable in `outcomes'{

    local vallab : label (en_outcome) `outcome'
    scalar cut = 59.5
    
    foreach cohort in M50 F55{
        
        foreach runvar in std_weeks {
            
            foreach model in rdrobust {
                
                qui sum age if cohort == "`cohort'" & model == "`model'"
                scalar min = r(min)
                scalar max = r(max)
                
                tw (rcap ci_lower ci_upper age, lcolor(ebblue) lp(solid))           ///
                (rcap ci_l90 ci_u90 age, lcolor(maroon) lp(solid))                  ///
                (scatter coef age, mcolor(black))                                   ///
                if (cohort == "`cohort'" & outcome == "`variable'" &                ///
                model == "`model'" & runvar == "`runvar'" & !mi(age)),              ///
                legend(position(bottom) rows(1) order(2 "Point estimate"            ///
                1 "95% confidence interval")) xline(`=cut', lcolor(gs7))            ///
                yline(0, lp(solid)) ytitle(`vallab')                                ///
                xlabel(`=min'(1)`=max') xtitle(Age)                                 ///
                ylabel(#10, format(%010.3fc) labs(vsmall))
        
                graph export "${graphs}/latest/PILA/age/`variable'_`cohort'_`runvar'_`model'.pdf", replace
        
            }
        }
        scalar cut = 54.5
    }
    local ++outcome
}