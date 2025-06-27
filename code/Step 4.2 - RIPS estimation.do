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

global extensive service consul proce urg hosp cons_psico estres        ///
cardiovascular infarct chronic diag_mental

global intensive nro_servicios nro_consultas nro_procedimientos         ///
nro_urgencias nro_Hospitalizacion

global first_cohorts M50 F55

global outcomes $extensive pre_MWI $intensive

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
    
    keep $outcomes poblacion* age std_weeks eligible_w // For efficiency
    
}
	
   
****************************************************************************
**#          2. Difference in discontinuities
****************************************************************************
local replace replace
gen post = (age >= 60 & poblacion_M50 == 1) | (age >= 55 & poblacion_F55 == 1)

foreach cohort in $first_cohorts {
    
    foreach outcome in $outcomes {
            
    dis as err "Cohort: `cohort'; Outcome: `outcome'; "                 ///
    "Runvar: std_weeks -> (2) Difference in discontinuities"
                
    qui rdrobust `outcome' std_weeks if poblacion_`cohort' == 1 &       ///
        post == 0, kernel(uniform) masspoints(check)

    scalar bw_pre = e(hr)

    qui rdrobust `outcome' std_weeks if poblacion_`cohort' == 1 &       ///
        post == 1, kernel(uniform) masspoints(check)

    scalar bw_post = e(hr)

    scalar bw_avg = (bw_pre + bw_post) / 2

    reg `outcome' i.eligible_w##c.std_weeks##i.post if                  ///
        poblacion_`cohort' == 1 & abs(std_weeks) <= bw_avg, robust
    
    * Save estimation results in dataset
    regsave 1.eligible_w#1.post using "${output}/RIPS_results_diffdisc.dta", ///
    `replace' ci level(95) addlabel(outcome, `outcome', cohort, `cohort',    ///
    runvar, std_weeks)
    
    local replace append
        
    }
}

****************************************************************************
**# 		3. RDD by age
****************************************************************************
local replace replace
foreach cohort in $first_cohorts {
    
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

                mat beta = e(tau_bc)            // Store robust beta
                mat vari = e(se_tau_rb)^2       // Store robust SE

                * Save estimation results in dataset
                cap noi regsave using "${output}/RIPS_results.dta", `replace'   ///
                coefmat(beta) varmat(vari) ci level(95)                         ///
                addlabel(outcome, `outcome', cohort, `cohort', age, `age',      ///
                runvar, std_weeks, model, "rdrobust")
                
                clear results
                
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
                runvar, std_weeks, model, "rdhonest",                            ///
                ci_lower, `li95', ci_upper, `ui95', m_bound, `M')
                
                local replace append
        }
    }
}

        

log close
