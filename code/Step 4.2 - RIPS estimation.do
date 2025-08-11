/*************************************************************************
*************************************************************************			       	
                RIPS estimation
             
    1) Created by: Pablo Uribe
               Yale University
               p.uribe@yale.edu
                
    2) Date: June 25, 2025

    3) Objective: Perform estimations for the health outcomes

    4) Output:	- RIPS_results.dta
*************************************************************************
*************************************************************************/	
clear all

****************************************************************************
*       Global directory, parameters and assumptions:
****************************************************************************

global cohorts M50 F55 M54 F59

global extensive consul proce urg estres        ///
cardiovascular infarct chronic diag_mental

global intensive nro_servicios nro_consultas nro_procedimientos         ///
nro_urgencias

global first_cohorts M50 F55

global outcomes $extensive $intensive hosp cons_psico nro_Hospitalizacion

cap mkdir "${graphs}/latest/RIPS"

set scheme white_tableau
set graphics off

capture log close

log	using "${logs}/RIPS estimations.smcl", replace


****************************************************************************
**#          1. Data filtering and estimation variables
****************************************************************************
dis as err "(1) Data filtering and estimation variables"

use if (poblacion_M50 == 1 | poblacion_F55 == 1) using          ///
    "${data}/Estimation_sample_RIPS.dta", clear //Only use those cohorts (faster)

keep if (inrange(age, 59, 69) & poblacion_M50 == 1) |           ///
        (inrange(age, 54, 64) & poblacion_F55 == 1)

* Process raw data to create and label relevant variables
quietly{
    
    rename (nro_serviciosHospitalizacion nro_serviciosurgencias             ///
    nro_serviciosprocedimientos nro_serviciosconsultas)                     ///
    (nro_Hospitalizacion nro_urgencias nro_procedimientos nro_consultas)
    
    egen nro_servicios = rowtotal(nro_Hospitalizacion nro_urgencias         ///
    nro_procedimientos nro_consultas)
    
    gen eligible_w = (std_weeks > 0)
    
    labvars cardiovascular chronic cons_psico consul estres hosp infarct    ///
    nro_Hospitalizacion nro_consultas nro_procedimientos nro_servicios      ///
    nro_urgencias pre_MWI proce service urg diag_mental                     ///
    "Cardiovascular" "Chronic disease" "Consultation with psychologist"     ///
    "Probability of consultation" "Stress" "Probability of hospitalization" ///
    "Infarct" "Number of hospitalizations" "Number of consultations"        ///
    "Number of procedures" "Number of services" "Number of ER visits"       ///
    "Multi-morbidity index" "Probability of procedures"                     ///
    "Probability of health service" "Probability of ER visit" "Mental diagnosis"
    
    keep $outcomes poblacion* age std_weeks eligible_w personabasicaid // For efficiency
    
}

/*
****************************************************************************
**#          2. Difference in discontinuities
****************************************************************************
local replace replace
gen post = (age >= 60 & poblacion_M50 == 1) | (age >= 55 & poblacion_F55 == 1)

foreach cohort in $first_cohorts {
    
    preserve
    keep if poblacion_`cohort' == 1
    
    foreach outcome in $outcomes {
            
    dis as err "Cohort: `cohort'; Outcome: `outcome'; "                 ///
    "Runvar: std_weeks -> (2) Difference in discontinuities"
           
    clear results 

    scalar bw_avg = 21
    
    reg `outcome' i.eligible_w##c.std_weeks##i.post i.age if             ///
        poblacion_`cohort' == 1 & abs(std_weeks) <= bw_avg, vce(cluster personabasicaid)
    
    * Save estimation results in dataset
    regsave 1.eligible_w#1.post using "${output}/RIPS_results_diffdisc.dta", ///
    `replace' ci level(95) addlabel(outcome, `outcome', cohort, `cohort',    ///
    runvar, std_weeks)
    
    local replace append
        
    }
    
    restore
}
*/
****************************************************************************
**# 		3. RDD by age
****************************************************************************

drop if std_weeks == 0
local replace replace
foreach cohort in $first_cohorts {
    
    preserve
    keep if poblacion_`cohort' == 1
    
    qui sum age if poblacion_`cohort' == 1
    local min = r(min)
    local max = r(max)
    
    foreach outcome in $outcomes {
            
            forval age = `min'/`max'{
                
                dis as err "Cohort: `cohort'; Outcome: `outcome'; Age: "    ///
                "`age'; Runvar: std_weeks -> (3) Age by age RDD"
                
                clear results
                
                cap noi rdrobust `outcome' std_weeks if poblacion_`cohort' == 1  ///
                & age == `age', vce(hc3) masspoints(check)

                mat beta = e(tau_cl)            // Store robust beta
                mat vari = e(se_tau_cl)^2       // Store robust SE

                local h_left = e(h_l)
                
                local betarb = e(tau_bc)
                local serb   = e(se_tau_rb)

                qui sum `outcome' if poblacion_`cohort' == 1 & age == `ages' ///
                    & inrange(std_weeks, -`h_left', -1)
                
                local c_mean = r(mean)
                
                * Save estimation results in dataset
                cap noi regsave using "${output}/RIPS_results.dta", `replace'   ///
                coefmat(beta) varmat(vari) ci level(95)                         ///
                addlabel(outcome, `outcome', cohort, `cohort', age, `age',      ///
                runvar, std_weeks, model, "rdrobust", coef_rb, `betarb',        ///
                se_rb, `serb', c_mean, `c_mean')
                
                clear results
                
                /*
                ** RDHonest estimation
                cap noi rdhonest `outcome' std_weeks if poblacion_`cohort' == 1 & ///
                age == `age'
                
                cap noi mat beta = e(est)            // Store robust beta
                cap noi mat vari = e(se)^2           // Store robust SE
                local li95       = e(TCiL)
                local ui95       = e(TCiU)
                local M          = e(M)
                
                cap noi regsave using "${output}/RIPS_results.dta", append      ///
                coefmat(beta) varmat(vari)                                      ///
                addlabel(outcome, `outcome', cohort, `cohort', age, `age',      ///
                runvar, std_weeks, model, "rdhonest",                           ///
                ci_lower, `li95', ci_upper, `ui95', m_bound, `M')
                */
                
                local replace append
        }
    }
    restore
}


****************************************************************************
**#         4. Whole age panel regressions (with plots)
****************************************************************************

tab age if poblacion_M50 == 1, gen(ageM50)
tab age if poblacion_F55 == 1, gen(ageF55)

local replace replace
foreach restriction in 0 1 2 {
    
    if `restriction' == 0   global outcomes $extensive $intensive
    if `restriction' == 1   global outcomes hosp nro_Hospitalizacion
    if `restriction' == 2   global outcomes cons_psico
    
    foreach cohort in $first_cohorts {
    
        if      "`cohort'" == "M50" & `restriction' == 0   local ages "59, 69"
        else if "`cohort'" == "M50" & `restriction' == 1   local ages "62, 69"
        else if "`cohort'" == "M50" & `restriction' == 2   local ages "65, 69"
        else if "`cohort'" == "F55" & `restriction' == 0   local ages "54, 64"
        else if "`cohort'" == "F55" & `restriction' == 1   local ages "57, 64"
        else if "`cohort'" == "F55" & `restriction' == 2   local ages "60, 64"
        
        foreach outcome in $outcomes {
                        
            clear results
        
            dis as err "Cohort: `cohort'; Outcome: `outcome' -> (4) Whole age panel RDD"
        
            qui sum `outcome' if poblacion_`cohort' == 1 & inrange(age, `ages') ///
                    & inrange(std_weeks, -21, -1)
                
            local c_mean = r(mean)
        
            cap noi rdrobust `outcome' std_weeks if poblacion_`cohort' == 1 &        ///
                inrange(age, `ages'), vce(cluster personabasicaid) covs(age`cohort'*)

            mat beta = e(tau_bc)            // Store robust beta
            mat vari = e(se_tau_rb)^2       // Store robust SE
                
            local betarb = e(tau_bc)
            local serb   = e(se_tau_rb)
            local eff_n  = e(N_h_l) + e(N_h_r)
                
            local HL = 21
            local HR = 21        

            * Save estimation results in dataset
            cap noi regsave using "${output}/RIPS_results_pool.dta", `replace'       ///
            coefmat(beta) varmat(vari) ci level(95)                                  ///
            addlabel(outcome, `outcome', cohort, `cohort', bw, `HL', eff_n, `eff_n', ///
            method, "rdrobust", c_mean, `c_mean', coef_rb, `betarb', se_rb, `serb')
            
            qui reg `outcome' i.eligible_w##c.std_weeks i.age if             ///
                poblacion_`cohort' == 1 & inrange(std_weeks, -`HL', `HR') &  ///
                inrange(age, `ages'), cluster(personabasicaid)

            cap noi regsave 1.eligible_w using "${output}/RIPS_results_pool.dta", ///
            append ci level(95) addlabel(outcome, `outcome', cohort, `cohort',    ///
            bw, `HL', method, "reg", c_mean, `c_mean')

            
            cap rdplot `outcome' std_weeks if inrange(std_weeks,-`HL',`HR') &   ///
            inrange(age, `ages'), vce(cluster personabasicaid) p(1)             ///
            kernel(triangular) h(`HR' `HR') binselect(esmv) covs(age`cohort'*)  ///
            graph_options(xtitle(Distance to week of birth's cutoff) ytitle("") ///
            legend(off) ylabel(, format(%07.3fc)))

            cap graph export "${graphs}/latest/RIPS/`outcome'_`cohort'_rdplot_ages.png",  ///
                replace width(1920) height(1080)

            local replace append
        }
    }
}





log close
