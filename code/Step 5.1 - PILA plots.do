/*************************************************************************
 *************************************************************************			       	
               PILA results plots

1) Created by: Pablo Uribe
               Yale University
               p.uribe@yale.edu

2) Date: July 2, 2025

3) Objective: Plot the labor market results
*************************************************************************
*************************************************************************/	
clear all

****************************************************************************
*       Global directory, parameters and assumptions:
****************************************************************************

set graphics off
set scheme white_tableau
cap mkdir "${graphs}/latest/PILA/age"
cap mkdir "${graphs}/latest/PILA/time"

****************************************************************************
**#              1. Call data and set labels
****************************************************************************

use "${output}/PILA_results.dta", clear

** Might be temporary, fix eventually
append using "${output}/PILA_results_rdhonest.dta", gen(o)
drop if o == 1 & (model == "rdrobust" | !mi(year) | runvar == "std_days")
drop if mi(coef_rb) & o == 0
drop o year month

*gen date = ym(year, month)
*format date %tm

encode outcome, gen(en_outcome)
label def labout 1 "Contributes to any pension fund"                ///
2 "Contributes to Colpensiones" 3 "Pension flag in PILA"            ///
4 "Pension flag in PILA (cumulative)"                               ///
5 "Pension proxy with IBC" 6 "Pension proxy with IBC (cumulative)"  ///
7 "Real monthly wage"

label val en_outcome labout

****************************************************************************
**#              2. Plot PILA-year-level results
****************************************************************************
/*
levelsof outcome, local(outcomes)
local outcome = 1
foreach variable in `outcomes'{

    if inlist("`variable'", "pila_salario_r", "pila_salario_r_0"){
        local dec = 0
    }
    else{
        local dec = 3
    }

    local vallab : label (en_outcome) `outcome'

    foreach cohort in M50 F55{
        
        foreach runvar in std_weeks std_days {
            
            foreach model in rdrobust rdhonest {
                
                tw (rspike ci_lower ci_upper date, lcolor(ebblue) lp(solid))        ///
                (scatter coef date, mcolor(ebblue))                                 ///
                if (cohort == "`cohort'" & outcome == "`variable'" &                ///
                model == "`model'" & runvar == "`runvar'" & !mi(date)),             ///
                legend(position(bottom) rows(1) order(2 "Point estimate"            ///
                1 "95% confidence interval")) xline(`=ym(2010,7)', lcolor(gs7))     ///
                yline(0, lp(solid)) ytitle(`vallab')                                ///
                xlabel(`=ym(2009,1)'(2)`=ym(2011,12)', angle(45) labs(vsmall))      ///
                xtitle(Date) ylabel(#10, format(%010.`dec'fc) labs(vsmall))         ///
                subtitle(Cohort: `cohort', size(medsmall))
        
                graph export "${graphs}/latest/PILA/time/`variable'_`cohort'_`runvar'_`model'.png", replace
        
            }
        }
    }
    local ++outcome
}

*/

****************************************************************************
**#              3. Plot age-level results
****************************************************************************

drop if (cohort == "F55" & inlist(age, 52, 66)) |       ///
        (cohort == "M50" & inlist(age, 57, 71))


gen ci_l90 = coef - stderr*1.645
gen ci_u90 = coef + stderr*1.645
        
levelsof outcome, local(outcomes)
local outcome = 1
foreach variable in `outcomes'{

    if inlist("`variable'", "pila_salario_r", "pila_salario_r_0"){
        local dec = 0
    }
    else{
        local dec = 3
    }

    local vallab : label (en_outcome) `outcome'
    scalar cut = 59.5
    
    foreach cohort in M50 F55{
        
        foreach runvar in std_weeks {
            
            foreach model in rdrobust rdhonest {
                
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
                ylabel(#10, format(%010.`dec'fc) labs(vsmall))
        
                graph export "${graphs}/latest/PILA/age/`variable'_`cohort'_`runvar'_`model'.png", replace
        
            }
        }
        scalar cut = 54.5
    }
    local ++outcome
}


****************************************************************************
**#              4. Difference-in-discontinuities plots
****************************************************************************

use "${output}/PILA_results_diffdisc.dta", clear

encode outcome, gen(en_outcome)

foreach cohort in M50 F55 {

    foreach runvar in std_weeks {
        
        tw (bar coef en_outcome, barwidth(0.7))                                 ///
        (rcap ci_lower ci_upper en_outcome)                                     ///
        if cohort == "`cohort'" & outcome != "pila_salario_r_0" &               ///
        runvar == "`runvar'",                                                   ///
        legend(position(bottom) rows(1) order(1 "Point estimate"                ///
        2 "95% confidence interval")) ylabel(,format(%010.3fc))                 ///
        yline(0, lpattern(solid) lcolor(black)) xtitle(Variable)                ///
        subtitle(Cohort `cohort'; Runvar: `runvar')                             ///
        xlabel(1 `""Contributes to" "any pension fund""'                        ///
        2 `""Contributes to" "Colpensiones""' 3 `""Pension flag in" "PILA""'    ///
        4 `""Pension flag in" "PILA (cumulative)""'                             ///
        5 `""Pension proxy" "with IBC""' 6 `""Pension proxy" "with IBC (cumulative)""') 
        
        graph export "${graphs}/latest/PILA/DiffD_`cohort'_`runvar'.png", replace
        
    }
}


keep if outcome == "pila_salario_r_0"

sort runvar

gen counter = _n

tw (bar coef counter, barwidth(0.7))                                        ///
(rcap ci_lower ci_upper counter),                                           ///
legend(position(bottom) rows(1) order(1 "Point estimate"                    ///
2 "95% confidence interval"))                                               ///
yline(0, lpattern(solid) lcolor(black))                                     ///
xlabel(1 "Women (weeks)" 2 "Men (weeks)")                                   ///
ylabel(#8, format(%10.0fc)) xtitle("") ytitle(Real monthly wage in COP)

graph export "${graphs}/latest/PILA/DiffD_wages.png", replace
