/*************************************************************************
 *************************************************************************			       	
				PILA estimation
			 
1) Created by: Pablo Uribe
			   Yale University
			   p.uribe@yale.edu
				
2) Date: June 17, 2025

3) Objective: Perform monthly estimations for labor market outcomes across
			  cohorts

4) Output:	- PILA_results.dta
*************************************************************************
*************************************************************************/	
clear all
set graphics off
****************************************************************************
*		Global directory, parameters and assumptions:
****************************************************************************

global first_cohorts    M50 F55
global second_cohorts   M54 F59
global outcomes         codigo_pension pension pension_cum colpensiones     ///
                        pila_salario_r_0 pension_ibc pension_ibc_cum


capture log close

log	using "${logs}\PILA estimations.smcl", replace

use if (poblacion_M50 == 1 | poblacion_F55 == 1) using          ///
       "${data}/Estimation_sample_PILA.dta", clear

/*
****************************************************************************
**# 		1. Year by year RDD
****************************************************************************

local replace replace
forval year = 2009/2020 { // Loop through all years

    * First cohorts (M50 & F55) retire in 2010, so only one year before and after
    if inrange(`year', 2009, 2011) {
        
        foreach cohort in $first_cohorts {
        
            foreach outcome in $outcomes {
                
                forval month = 1/12 {
                    
                    foreach runvar in std_weeks std_days {
                        
                    dis as err "Cohort: `cohort'; Outcome: `outcome'; Date: "        ///
                    "`year'-`month'; Runvar: `runvar' -> (1) Year by year RDD"
                    
                    cap mat drop beta vari
                    
                    ** RDRobust estimation
                    cap noi rdrobust `outcome' `runvar' if poblacion_`cohort' == 1 & ///
                    fecha_pila == ym(`year',`month'), vce(hc3)

                    cap noi mat beta = e(tau_bc)            // Store robust beta
                    cap noi mat vari = e(se_tau_rb)^2       // Store robust SE

                    * Save estimation results in dataset
                    cap noi regsave using "${output}/PILA_results.dta", `replace'   ///
                    coefmat(beta) varmat(vari) ci level(95)                         ///
                    addlabel(outcome, `outcome', cohort, `cohort', year, `year',    ///
                    month, `month', runvar, `runvar', model, "rdrobust")
                    
                    ** RDHonest estimation
                    cap noi rdhonest `outcome' `runvar' if poblacion_`cohort' == 1 & ///
                    fecha_pila == ym(`year',`month')
                    
                    cap noi mat beta = e(est)            // Store robust beta
                    cap noi mat vari = e(se)^2           // Store robust SE
                    local li95       = e(TCiL)
                    local ui95       = e(TCiU)
                    local M          = e(M)
                    
                    cap noi regsave using "${output}/PILA_results.dta", append      ///
                    coefmat(beta) varmat(vari)                                      ///
                    addlabel(outcome, `outcome', cohort, `cohort', year, `year',    ///
                    month, `month', runvar, `runvar', model, "rdhonest",            ///
                    ci_lower, `li95', ci_upper, `ui95', m_bound, `M')
                    
                    
                    
                    local replace append
                    }
                }
            }
        }
    }
	
    * Second cohorts (M54 & F59) retire in Dec. 2014, so 6 years pre and 6 post.
    * This loop happens for all years in the loop (2009/2020)
    /*foreach cohort in $second_cohorts{
        
        foreach outcome in $outcomes{
            
            forval month = 1/12{
                
                rdrobust `outcome' std_weeks if poblacion_`cohort' == 1 &       ///
                fecha_pila == ym(`year',`month'), vce(cluster std_weeks)

                mat beta = e(tau_bc)				// Store robust beta
                mat vari = e(se_tau_rb)^2			// Store robust SE

            * Save estimation results in dataset
            regsave using "${output}/PILA_results.dta", append coefmat(beta)    ///
            varmat(vari) ci level(95) addlabel(outcome, `outcome', cohort, 	    ///
            `cohort', year, `year', month, `month')
            }
        }
    }*/
}


****************************************************************************
**# 		2. Whole monthly panel regressions (with plots)
****************************************************************************
preserve

keep if inrange(year, 2009, 2011)


gen eligible_w = (std_weeks > 0)
gen eligible_d = (std_days > 0)


*** Whole monthly panel regressions

foreach cohort in $first_cohorts {
    
    foreach outcome in $outcomes {
        
        local varlab: variable label `outcome'
        
        if inlist("`outcome'", "pila_salario_r", "pila_salario_r_0") {
            local dec = 0
            local pren "10"
        }
        else {
            local dec = 3
            local pren "07"
        }
        
        local elig eligible_w
        local name "week"
        foreach runvar in std_weeks std_days {
            
            dis as err "Cohort: `cohort'; Outcome: `outcome'; "             ///
            "Runvar: `runvar' -> (2) Whole monthly panel RDD"
            
            qui rdrobust `outcome' `runvar' if poblacion_`cohort' == 1,     ///
                vce(hc3)

            local HL = e(h_l)
            local HR = e(h_r)

            local B: 	dis %`pren'.`dec'fc e(tau_bc)
            local B: 	dis strtrim("`B'")

            local t = e(tau_bc) / e(se_tau_rb)

            local N: 	dis %10.0fc e(N_b_l) + e(N_b_r)
            local N: 	dis strtrim("`N'")

            if abs(`t') >= 1.645 {
                local B = "`B'*"
            }
            if abs(`t') >= 1.96 {
                local B = "`B'*"
            }
            if abs(`t') >= 2.576 {
                local B = "`B'*"
            }


            qui reg `outcome' i.`elig'##c.`runvar' if poblacion_`cohort' == 1 & ///
                inrange(`runvar', -`HL', `HR'), vce(hc3)

            local Breg: dis %`pren'.`dec'fc _b[1.`elig']
            local Breg: dis strtrim("`Breg'")

            local t = _b[1.`elig'] / _se[1.`elig']

            if abs(`t') >= 1.645 {
                local Breg = "`Breg'*"
            }
            if abs(`t') >= 1.96 {
                local Breg = "`Breg'*"
            }
            if abs(`t') >= 2.576 {
                local Breg = "`Breg'*"
            }

			local HL: 	dis %7.2f `HL'
			
            rdplot `outcome' `runvar' if inrange(`runvar',-`HL',`HR'),          ///
            vce(hc3) p(1) kernel(triangular) h(`HR' `HR') 	                    ///
            binselect(esmv)	graph_options(title(`varlab', size(medium) span)    ///
            subtitle(Cohort: `cohort'; `name' around cutoff: `HL', size(small)) ///
            xtitle(Distance to `name' of birth's cutoff) ytitle("")             ///
            legend(rows(1) position(bottom)) ylabel(, format(%`pren'.`dec'fc))  ///
            note(`""Rdrobust {&beta}: `B'. Standard RDD {&beta}: `Breg'. Effective number of observations: `N'.""'))

			
            graph export "${graphs}\new\\`outcome'_`cohort'_`runvar'_rdplot.png",   ///
                replace width(1920) height(1080)


            binscatterhist `outcome' `runvar' if poblacion_`cohort' == 1 &      ///
            inrange(`runvar', -`HL', `HR'), vce(robust)                         ///
            rd(0) linetype(lfit) title(`varlab', size(medium) span)             ///
            subtitle(Cohort: `cohort'; `name' around cutoff: `HL', size(small)) ///
            xtitle(Distance to `name' of birth's cutoff) ytitle("")             ///
            ylabel(, format(%`pren'.`dec'fc))                                   ///
            note(`""Rdrobust: `B'. Standard RDD: `Breg'. Effective number of observations: `N'.""')

            graph export "${graphs}\new\\`outcome'_`cohort'_`runvar'_bscatter.png", ///
                replace width(1920) height(1080)

            local elig eligible_d
            local name day
        }
    }
}

*/

****************************************************************************
**# 		3. Collapse at age level
****************************************************************************
*restore

tempvar dia_pila
gen `dia_pila' = dofm(fecha_pila + 1) - 1
format %td `dia_pila'

gen age = age(fechantomode, `dia_pila')

                        

collapse (firstnm) poblacion* std_weeks std_days                    ///
         (mean) pila_salario_r_0                                    ///
         (max) pension codigo_pension pension_cum colpensiones      ///
         pension_ibc pension_ibc_cum, by(personabasicaid age)

sort personabasicaid age

gen eligible_w = (std_weeks > 0)
gen eligible_d = (std_days > 0)

****************************************************************************
**# 		4. Difference in discontinuities
****************************************************************************

local replace replace
gen post = (age >= 60 & poblacion_M50 == 1) | (age >= 55 & poblacion_F55 == 1)

foreach cohort in $first_cohorts {
    
    foreach outcome in $outcomes {
        
        local elig eligible_w
        
        foreach runvar in std_weeks std_days {
            
        dis as err "Cohort: `cohort'; Outcome: `outcome'; "                 ///
        "Runvar: `runvar' -> (3) Difference in discontinuities"
                
        clear results 
        
        qui rdrobust `outcome' `runvar' if poblacion_`cohort' == 1 &        ///
            post == 0, kernel(uniform)

        scalar bw_pre = e(h_r)

        qui rdrobust `outcome' `runvar' if poblacion_`cohort' == 1 &        ///
            post == 1, kernel(uniform)

        scalar bw_post = e(h_r)

        scalar bw_avg = (bw_pre + bw_post) / 2

        if mi(bw_avg) {
            scalar bw_avg = 21
        }
        
        reg `outcome' i.`elig'##c.`runvar'##i.post if poblacion_`cohort' == 1 &  ///
            abs(`runvar') <= bw_avg, robust
        
        * Save estimation results in dataset
        regsave 1.`elig'#1.post using "${output}/PILA_results_diffdisc.dta",    ///
        `replace' ci level(95) addlabel(outcome, `outcome', cohort, `cohort',   ///
        runvar, `runvar')
        
        local replace append
        local elig eligible_d
        }
    }
}

/*      
****************************************************************************
**# 		5. RDD by age
****************************************************************************

foreach cohort in $first_cohorts {
    
    qui sum age if poblacion_`cohort' == 1
    local min = r(min) + 1
    local max = r(max) - 1
    
    foreach outcome in $outcomes {
        
        foreach runvar in std_weeks std_days {
            
            forval age = `min'/`max'{
                
                dis as err "Cohort: `cohort'; Outcome: `outcome'; Age: "    ///
                "`age'; Runvar: `runvar' -> (4) Age by age RDD"
                
				clear results
				
                cap noi rdrobust `outcome' `runvar' if poblacion_`cohort' == 1  ///
                & age == `age', vce(hc3) masspoints(check)

                mat beta = e(tau_bc)            // Store robust beta
                mat vari = e(se_tau_rb)^2       // Store robust SE

                * Save estimation results in dataset
                cap noi regsave using "${output}/PILA_results.dta", append      ///
                coefmat(beta) varmat(vari) ci level(95)                         ///
                addlabel(outcome, `outcome', cohort, `cohort', age, `age',      ///
                runvar, `runvar', model, "rdrobust")
                
				clear results
                
                ** RDHonest estimation
                cap noi rdhonest `outcome' `runvar' if poblacion_`cohort' == 1 & ///
                age == `age'
                
                cap noi mat beta = e(est)            // Store robust beta
                cap noi mat vari = e(se)^2           // Store robust SE
                local li95       = e(TCiL)
                local ui95       = e(TCiU)
                local M          = e(M)
                
                cap noi regsave using "${output}/PILA_results.dta", append      ///
                coefmat(beta) varmat(vari)                                      ///
                addlabel(outcome, `outcome', cohort, `cohort', age, `age',      ///
                runvar, `runvar', model, "rdhonest",                            ///
                ci_lower, `li95', ci_upper, `ui95', m_bound, `M')
                
            }
        }
    }
}
        
        
****************************************************************************
**# 		6. Whole age panel regressions (with plots)
****************************************************************************

foreach cohort in $first_cohorts {
    
    if "`cohort'" == "M50"      local ages "59, 62"
    else                        local ages "54, 57"
    
    foreach outcome in $outcomes {
        
        local varlab: variable label `outcome'
        
        if inlist("`outcome'", "pila_salario_r", "pila_salario_r_0") {
            local dec = 0
            local pren "10"
        }
        else {
            local dec = 3
            local pren "07"
        }
        
        local elig eligible_w
        local name "week"
        foreach runvar in std_weeks std_days {
        
            dis as err "Cohort: `cohort'; Outcome: `outcome'; "             ///
            "Runvar: `runvar' -> (5) Whole age panel RDD"
        
            qui rdrobust `outcome' `runvar' if poblacion_`cohort' == 1 &    ///
                inrange(age, `ages'), vce(hc3)

            local HL = e(h_l)
            local HR = e(h_r)

            local B: 	dis %`pren'.`dec'fc e(tau_bc)
            local B: 	dis strtrim("`B'")

            local t = e(tau_bc) / e(se_tau_rb)

            local N: 	dis %10.0fc e(N_b_l) + e(N_b_r)
            local N: 	dis strtrim("`N'")

            if abs(`t') >= 1.645 {
                local B = "`B'*"
            }
            if abs(`t') >= 1.96 {
                local B = "`B'*"
            }
            if abs(`t') >= 2.576 {
                local B = "`B'*"
            }


            qui reg `outcome' i.`elig'##c.`runvar' if poblacion_`cohort' == 1 & ///
                inrange(`runvar', -`HL', `HR') & inrange(age, `ages'),          ///
                vce(hc3)

            local Breg: dis %`pren'.`dec'fc _b[1.`elig']
            local Breg: dis strtrim("`Breg'")

            local t = _b[1.`elig'] / _se[1.`elig']

            if abs(`t') >= 1.645 {
                local Breg = "`Breg'*"
            }
            if abs(`t') >= 1.96 {
                local Breg = "`Breg'*"
            }
            if abs(`t') >= 2.576 {
                local Breg = "`Breg'*"
            }

            local HL: 	dis %7.2f `HL'

            rdplot `outcome' `runvar' if inrange(`runvar',-`HL',`HR') &         ///
            inrange(age, `ages'), vce(hc3) p(1) kernel(triangular)              ///
            h(`HR' `HR') binselect(esmv)                                        ///
            graph_options(title(`varlab', size(medium) span)                    ///
            subtitle(Cohort: `cohort'; `name' around cutoff: `HL', size(small)) ///
            xtitle(Distance to `name' of birth's cutoff) ytitle("")             ///
            legend(rows(1) position(bottom)) ylabel(, format(%`pren'.`dec'fc))  ///
            note(`""Rdrobust {&beta}: `B'. Standard RDD {&beta}: `Breg'. Effective number of observations: `N'.""'))

            scalar b_l = e(J_star_l)
            scalar b_r = e(J_star_r)
            scalar b_avg = (b_l + b_r) / 2

            graph export "${graphs}\new\\`outcome'_`cohort'_`runvar'_rdplot_ages.png",  ///
                replace width(1920) height(1080)


            binscatterhist `outcome' `runvar' if poblacion_`cohort' == 1 &      ///
            inrange(`runvar', -`HL', `HR') & inrange(age, `ages'),              ///
            vce(robust) rd(0) linetype(lfit)                                    ///
            title(`varlab', size(medium) span)                                  ///
            subtitle(Cohort: `cohort'; `name' around cutoff: `HL', size(small)) ///
            xtitle(Distance to `name' of birth's cutoff) ytitle("")             ///
            ylabel(, format(%`pren'.`dec'fc))                                      ///
            note(`""Rdrobust: `B'. Standard RDD: `Breg'. Effective number of observations: `N'.""')

            graph export "${graphs}\new\\`outcome'_`cohort'_`runvar'_bscatter_ages.png", ///
                replace width(1920) height(1080)

            local elig eligible_d
            local name day
        }
    }
}
*/
        
log close

