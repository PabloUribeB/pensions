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

cap mkdir "${graphs}/latest/PILA"
cap mkdir "${graphs}/latest/PILA/placebo"
                        
capture log close

log	using "${logs}\PILA estimations.smcl", replace

use if (poblacion_M50 == 1 | poblacion_F55 == 1) using          ///
       "${data}/Estimation_sample_PILA.dta", clear


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
        
        foreach runvar in std_weeks {
            
        dis as err "Cohort: `cohort'; Outcome: `outcome'; "                 ///
        "Runvar: `runvar' -> (3) Difference in discontinuities"
                
        clear results 
        scalar bw_avg = 21
        
        reg `outcome' i.`elig'##c.`runvar'##i.post i.age if            ///
            poblacion_`cohort' == 1 & abs(`runvar') <= bw_avg, vce(cluster personabasicaid)
        
        * Save estimation results in dataset
        regsave 1.`elig'#1.post using "${output}/PILA_results_diffdisc.dta",    ///
        `replace' ci level(95) addlabel(outcome, `outcome', cohort, `cohort',   ///
        runvar, `runvar')
        
        local replace append
        local elig eligible_d
        }
    }
}

    
****************************************************************************
**# 		5. RDD by age
****************************************************************************
local replace replace
foreach cohort in $first_cohorts {
    
    qui sum age if poblacion_`cohort' == 1
    local min = r(min) + 1
    local max = r(max) - 7
    
    foreach outcome in $outcomes {
        
        foreach runvar in std_weeks {
            
            forval age = `min'/`max'{
                
                dis as err "Cohort: `cohort'; Outcome: `outcome'; Age: "    ///
                "`age'; Runvar: `runvar' -> (4) Age by age RDD"
                
				clear results
				
                cap noi rdrobust `outcome' `runvar' if poblacion_`cohort' == 1  ///
                & age == `age', vce(hc3) masspoints(check)

                mat beta = e(tau_cl)            // Store robust beta
                mat vari = e(se_tau_cl)^2       // Store robust SE

                local betarb = e(tau_bc)
                local serb   = e(se_tau_rb)
                
                * Save estimation results in dataset
                cap noi regsave using "${output}/PILA_results.dta", `replace'      ///
                coefmat(beta) varmat(vari) ci level(95)                         ///
                addlabel(outcome, `outcome', cohort, `cohort', age, `age',      ///
                runvar, `runvar', model, "rdrobust", coef_rb, `betarb', se_rb, `serb')
                
				clear results
                
                /*
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
                */
                local replace append
            }
        }
    }
}
     
        
****************************************************************************
**# 		6. Whole age panel regressions (with plots)
****************************************************************************

tab age if poblacion_M50 == 1, gen(ageM50)
tab age if poblacion_F55 == 1, gen(ageF55)

local replace replace
foreach cohort in $first_cohorts {
    
    if "`cohort'" == "M50"      local ages "60, 62"
    else                        local ages "55, 57"
    
    foreach outcome in $outcomes {
                
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
        foreach runvar in std_weeks {
        
            clear results
        
            dis as err "Cohort: `cohort'; Outcome: `outcome'; "             ///
            "Runvar: `runvar' -> (5) Whole age panel RDD"
        
            qui sum `outcome' if poblacion_`cohort' == 1 & inrange(age, `ages') ///
                & inrange(std_weeks, -21, -1)
            
            local c_mean = r(mean)
        
            rdrobust `outcome' `runvar' if poblacion_`cohort' == 1 &        ///
                inrange(age, `ages'), vce(cluster personabasicaid) covs(age`cohort'*) h(21)

            mat beta = e(tau_cl)            // Store robust beta
            mat vari = e(se_tau_cl)^2       // Store robust SE
            
            local betarb = e(tau_bc)
            local serb   = e(se_tau_rb)
            local eff_n  = e(N_h_l) + e(N_h_r)
            
            local HL = 21
            local HR = 21
           
            * Save estimation results in dataset
            regsave using "${output}/PILA_results_pool.dta", `replace'               ///
            coefmat(beta) varmat(vari) ci level(95)                                  ///
            addlabel(outcome, `outcome', cohort, `cohort', bw, `HL', eff_n, `eff_n', ///
            method, "rdrobust", runvar, `runvar', c_mean, `c_mean',                  ///
            coef_rb, `betarb', se_rb, `serb')

            qui reg `outcome' i.`elig'##c.`runvar' i.age if                 ///
                poblacion_`cohort' == 1 & inrange(`runvar', -`HL', `HR') &  ///
                inrange(age, `ages'), cluster(personabasicaid)

            cap noi regsave 1.`elig' using "${output}/PILA_results_pool.dta",   ///
            append ci level(95) addlabel(outcome, `outcome', cohort, `cohort',  ///
            bw, `HL', method, "reg", runvar, `runvar', c_mean, `c_mean')

            rdplot `outcome' `runvar' if inrange(`runvar',-`HL',`HR') &         ///
            inrange(age, `ages'), vce(cluster personabasicaid) p(1)             ///
            kernel(triangular) h(`HL') binselect(esmv) covs(age`cohort'*)       ///
            graph_options(xtitle(Distance to `name' of birth's cutoff)          ///
            ytitle("") legend(off) ylabel(, format(%`pren'.`dec'fc)))

            graph export "${graphs}/latest/PILA/`outcome'_`cohort'_`runvar'_rdplot_ages.png",  ///
                replace width(1920) height(1080)

            local replace append
        }
    }
}



*** Placebo
foreach cohort in $first_cohorts {
    
    if "`cohort'" == "M50"      local ages "58, 59"
    else                        local ages "53, 54"
    
    foreach outcome in $outcomes {
                
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
        foreach runvar in std_weeks {
        
            clear results
        
            dis as err "Cohort: `cohort'; Outcome: `outcome'; "             ///
            "Runvar: `runvar' -> (5) Whole age panel RDD"
        
            rdrobust `outcome' `runvar' if poblacion_`cohort' == 1 &        ///
                inrange(age, `ages'), vce(cluster personabasicaid) covs(age`cohort'*) h(21)

            mat beta = e(tau_cl)            // Store robust beta
            mat vari = e(se_tau_cl)^2       // Store robust SE
            
            local betarb = e(tau_bc)
            local serb   = e(se_tau_rb)
            local eff_n = e(N_h_l) + e(N_h_r)
            
            local HL = 21
            local HR = 21
            
            qui sum `outcome' if poblacion_`cohort' == 1 & inrange(age, `ages') ///
                & inrange(std_weeks, -21, -1)
            
            local c_mean = r(mean)


            * Save estimation results in dataset
            regsave using "${output}/PILA_results_pool.dta", `replace'               ///
            coefmat(beta) varmat(vari) ci level(95)                                  ///
            addlabel(outcome, `outcome', cohort, `cohort', bw, `HL', eff_n, `eff_n', ///
            method, "rdrobust", runvar, `runvar', c_mean, `c_mean',                  ///
            coef_rb, `betarb', se_rb, `serb', placebo, "yes")

            qui reg `outcome' i.`elig'##c.`runvar' i.age if                 ///
                poblacion_`cohort' == 1 & inrange(`runvar', -`HL', `HR') &  ///
                inrange(age, `ages'), cluster(personabasicaid)

            cap noi regsave 1.`elig' using "${output}/PILA_results_pool.dta",   ///
            append ci level(95) addlabel(outcome, `outcome', cohort, `cohort',  ///
            bw, `HL', method, "reg", runvar, `runvar', c_mean, `c_mean', placebo, "yes")

            rdplot `outcome' `runvar' if inrange(`runvar',-`HL',`HR') &         ///
            inrange(age, `ages'), vce(cluster personabasicaid) p(1)             ///
            kernel(triangular) h(`HL') binselect(esmv) covs(age`cohort'*)       ///
            graph_options(xtitle(Distance to `name' of birth's cutoff)          ///
            ytitle("") legend(off) ylabel(, format(%`pren'.`dec'fc)))

            graph export "${graphs}/latest/PILA/placebo/`outcome'_`cohort'_`runvar'_rdplot_ages.png",  ///
                replace width(1920) height(1080)

        }
    }
}
        
log close

