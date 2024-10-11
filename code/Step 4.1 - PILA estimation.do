/*************************************************************************
 *************************************************************************			       	
				PILA estimation
			 
1) Created by: Pablo Uribe
			   Yale University
			   p.uribe@yale.edu
				
2) Date: May 21, 2024

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
                        pila_salario_r_0


capture log close

log	using "${logs}\PILA estimations.smcl", replace


****************************************************************************
**# 		1. Prepare data
****************************************************************************

local replace replace

	
use "${data}\mensual_PILA", clear

* Process raw data to create relevant variables
quietly{
    
    gen poblacion_M50 = 1 if sexomode == 1 & inrange(fechantomode,      ///
                     date("01/01/1948", "MDY"), date("12/31/1952", "MDY"))
                     
    gen poblacion_M54 = 1 if sexomode == 1 & inrange(fechantomode,      ///
                     date("01/01/1952", "MDY"), date("12/31/1956", "MDY"))
                     
    gen poblacion_F55 = 1 if sexomode == 0 & inrange(fechantomode,      ///
                     date("01/01/1953", "MDY"), date("12/31/1957", "MDY"))
                     
    gen poblacion_F59 = 1 if sexomode == 0 & inrange(fechantomode,      ///
                     date("01/01/1957", "MDY"), date("12/31/1961", "MDY"))

    foreach var of varlist poblacion* {
        replace `var' = 0 if mi(`var')
    }

    * Generate cutoff points for each cohort
    gen     corte = date("07/31/1950", "MDY") if poblacion_M50 == 1
    replace corte = date("12/31/1954", "MDY") if poblacion_M54 == 1
    replace corte = date("07/31/1955", "MDY") if poblacion_F55 == 1
    replace corte = date("12/31/1959", "MDY") if poblacion_F59 == 1

    * Days from cutoff point for each group
    gen     std_days = datediff(corte, fechantomode, "d") if poblacion_M50 == 1
    replace std_days = datediff(corte, fechantomode, "d") if poblacion_M54 == 1
    replace std_days = datediff(corte, fechantomode, "d") if poblacion_F55 == 1
    replace std_days = datediff(corte, fechantomode, "d") if poblacion_F59 == 1
    
    
    gen fechaweek  = wofd(fechantomode)
    format %td corte
    gen corte_week = wofd(corte)

    gen std_weeks  = fechaweek - corte_week // Running variable

    * Replace missing values with zero for wages
    gen 	pila_salario_r_0 = pila_salario_r
    replace pila_salario_r_0 = 0 if mi(pila_salario_r)

    * Dummy for pension fund code
    gen codigo_pension = (!mi(afp_cod))

    * Dummy for whether they are affiliated to the public fund
    gen colpensiones = (inlist(afp_cod, "25-14", "25-11" ,"25-8", "ISSFSP"))

    keep codigo_pension pension colpensiones pila_salario_r_0 poblacion*    ///
    year month std_weeks std_days fecha_pila personabasicaid // For efficiency
    
    bys personabasicaid: egen ever_colpensiones = max(colpensiones)
    
    keep if ever_colpensiones == 1
    
    * Cumulative pension dummy
    gen pension_cum = pension
    replace pension_cum = pension_cum[_n-1] if pension_cum[_n-1] == 1
    
    labvars $outcomes "Contribution to any pension fund"    ///
    "Retirement sheet" "Retirement sheet cumulative"        ///
    "Contribution to Colpensiones" "Monthly wage (with 0's)"
    
}


****************************************************************************
**# 		2. Year by year RDD
****************************************************************************

forval year = 2009/2020 { // Loop through all years

    * First cohorts (M50 & F55) retire in 2010, so only one year before and after
    if inrange(`year', 2009, 2011) {
        
        foreach cohort in $first_cohorts {
        
            foreach outcome in $outcomes {
                
                forval month = 1/12 {
                    
                    foreach runvar in std_weeks std_days {
                        
                    dis as err "Cohort: `cohort'; Outcome: `outcome'; Date: "   ///
                    "`year'-`month'; Runvar: `runvar' -> (1) Year by year RDD"
                    
                    rdrobust `outcome' `runvar' if poblacion_`cohort' == 1 &    ///
                    fecha_pila == ym(`year',`month'), vce(cluster `runvar')

                    mat beta = e(tau_bc)            // Store robust beta
                    mat vari = e(se_tau_rb)^2       // Store robust SE

                    * Save estimation results in dataset
                    regsave using "${output}/PILA_results.dta", `replace'           ///
                    coefmat(beta) varmat(vari) ci level(95)                         ///
                    addlabel(outcome, `outcome', cohort, `cohort', year, `year',    ///
                    month, `month', runvar, `runvar')
                    
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
**# 		3. Whole monthly panel regressions (with plots)
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
        }
        else {
            local dec = 3
        }
        
        local elig eligible_w
        local name "week"
        foreach runvar in std_weeks std_days {
            
            dis as err "Cohort: `cohort'; Outcome: `outcome'; "             ///
            "Runvar: `runvar' -> (2) Whole monthly panel RDD"
            
            qui rdrobust `outcome' `runvar' if poblacion_`cohort' == 1,     ///
                vce(cluster `runvar')

            local HL = e(h_l)
            local HR = e(h_r)

            local B: 	dis %010.`dec'fc e(tau_bc)
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
                inrange(`runvar', -`HL', `HR'), vce(cluster `runvar')

            local Breg: dis %010.`dec'fc _b[1.`elig']
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


            rdplot `outcome' `runvar' if inrange(`runvar',-`HL',`HR'),          ///
            vce(cluster `runvar') p(1) kernel(triangular) h(`HR' `HR') 	        ///
            binselect(esmv)	graph_options(title(`varlab', size(medium) span)    ///
            subtitle(Cohort: `cohort'; `name' around cutoff: `HL', size(small)) ///
            xtitle(Distance to `name' of birth's cutoff) ytitle("")             ///
            legend(rows(1) position(bottom)) ylabel(, format(%010.`dec'fc))     ///
            note("Rdrobust {&beta}: `B'. Standard RDD {&beta}: `Breg';"         ///
            "Effective number of observations: `N'."))

            scalar b_l = e(J_star_l)
            scalar b_r = e(J_star_r)
            scalar b_avg = (b_l + b_r) / 2

            graph export "${graphs}\\`outcome'_`cohort'_`runvar'_rdplot.png",   ///
                replace width(1920) height(1080)


            biscatterhist `outcome' `runvar' if poblacion_`cohort' == 1 &       ///
            inrange(`runvar', -`HL', `HR'), n(b_avg) cluster(`runvar')          ///
            rd(0) linetype(lfit) title(`varlab', size(medium) span)             ///
            subtitle(Cohort: `cohort'; `name' around cutoff: `HL', size(small)) ///
            xtitle(Distance to `name' of birth's cutoff) ytitle("")             ///
            ylabel(, format(%010.`dec'fc))                                      ///
            note("Rdrobust {&beta}: `B'. Standard RDD {&beta}: `Breg';"         ///
            "Effective number of observations: `N'.")

            graph export "${graphs}\\`outcome'_`cohort'_`runvar'_bscatter.png", ///
                replace width(1920) height(1080)

            local elig eligible_d
            local name day
        }
    }
}



****************************************************************************
**# 		4. Collapse at age level
****************************************************************************
restore

tempvar dia_pila
gen `dia_pila' = dofm(fecha_pila + 1) - 1
format %td `dia_pila'

gen age = age(fechantomode,`dia_pila')

                        

collapse (firstnm) poblacion* std_weeks std_days                    ///
         (mean) pila_salario_r_0                                    ///
         (max) pension codigo_pension pension_cum colpensiones,     ///
         by(personabasicaid age)

sort personabasicaid age

gen eligible_w = (std_weeks > 0)
gen eligible_d = (std_days > 0)

****************************************************************************
**# 		5. Difference in discontinuities
****************************************************************************

local replace replace
gen post = (age >= 60)

foreach cohort in $first_cohorts {
    
    foreach outcome in $outcomes {
        
        local elig eligible_w
        
        foreach runvar in std_weeks std_days {
            
        dis as err "Cohort: `cohort'; Outcome: `outcome'; "                 ///
        "Runvar: `runvar' -> (3) Difference in discontinuities"
                    
        qui rdrobust `outcome' `runvar' if poblacion_`cohort' == 1 &        ///
            post == 0, kernel(uniform)

        scalar bw_pre = e(hr)

        qui rdrobust `outcome' `runvar' if poblacion_`cohort' == 1 &        ///
            post == 1, kernel(uniform)

        scalar bw_post = e(hr)

        scalar bw_avg = (bw_pre + bw_post) / 2

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
    
    replace post = (age >= 55)
}

      
****************************************************************************
**# 		6. RDD by age
****************************************************************************
        
qui sum age if poblacion_`cohort' == 1
local min = r(min)
local max = r(max)

foreach cohort in $first_cohorts {
    
    foreach outcome in $outcomes {
        
        foreach runvar in std_weeks std_days {
            
            forval age = `min'/`max'{
                
                dis as err "Cohort: `cohort'; Outcome: `outcome'; Age: "    ///
                "`age'; Runvar: `runvar' -> (4) Age by age RDD"
                
                rdrobust `outcome' `runvar' if poblacion_`cohort' == 1 &    ///
                age == `age', vce(cluster `runvar')

                mat beta = e(tau_bc)            // Store robust beta
                mat vari = e(se_tau_rb)^2       // Store robust SE

                * Save estimation results in dataset
                regsave using "${output}/PILA_results.dta", append              ///
                coefmat(beta) varmat(vari) ci level(95)                         ///
                addlabel(outcome, `outcome', cohort, `cohort', age, `age',      ///
                runvar, `runvar')
                
            }
        }
    }
}
        
        
****************************************************************************
**# 		7. Whole age panel regressions (with plots)
****************************************************************************

foreach cohort in $first_cohorts {
    
    if "`cohort'" == "M50"      local ages "59, 62"
    else                        local ages "54, 57"
    
    foreach outcome in $outcomes {
        
        local varlab: variable label `outcome'
        
        if inlist("`outcome'", "pila_salario_r", "pila_salario_r_0") {
            local dec = 0
        }
        else {
            local dec = 3
        }
        
        local elig eligible_w
        local name "week"
        foreach runvar in std_weeks std_days {
        
            dis as err "Cohort: `cohort'; Outcome: `outcome'; "             ///
            "Runvar: `runvar' -> (5) Whole age panel RDD"
        
            qui rdrobust `outcome' `runvar' if poblacion_`cohort' == 1 &    ///
                inrange(age, `ages'), vce(cluster `runvar')

            local HL = e(h_l)
            local HR = e(h_r)

            local B: 	dis %010.`dec'fc e(tau_bc)
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
                vce(cluster `runvar')

            local Breg: dis %010.`dec'fc _b[1.`elig']
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


            rdplot `outcome' `runvar' if inrange(`runvar',-`HL',`HR') &         ///
            inrange(age, `ages'), vce(cluster `runvar') p(1) kernel(triangular) ///
            h(`HR' `HR') binselect(esmv)                                        ///
            graph_options(title(`varlab', size(medium) span)                    ///
            subtitle(Cohort: `cohort'; `name' around cutoff: `HL', size(small)) ///
            xtitle(Distance to `name' of birth's cutoff) ytitle("")             ///
            legend(rows(1) position(bottom)) ylabel(, format(%010.`dec'fc))     ///
            note("Rdrobust {&beta}: `B'. Standard RDD {&beta}: `Breg';"         ///
            "Effective number of observations: `N'."))

            scalar b_l = e(J_star_l)
            scalar b_r = e(J_star_r)
            scalar b_avg = (b_l + b_r) / 2

            graph export "${graphs}\\`outcome'_`cohort'_`runvar'_rdplot_ages.png",  ///
                replace width(1920) height(1080)


            biscatterhist `outcome' `runvar' if poblacion_`cohort' == 1 &       ///
            inrange(`runvar', -`HL', `HR') & inrange(age, `ages'),              ///
            n(b_avg) cluster(`runvar') rd(0) linetype(lfit)                     ///
            title(`varlab', size(medium) span)                                  ///
            subtitle(Cohort: `cohort'; `name' around cutoff: `HL', size(small)) ///
            xtitle(Distance to `name' of birth's cutoff) ytitle("")             ///
            ylabel(, format(%010.`dec'fc))                                      ///
            note("Rdrobust {&beta}: `B'. Standard RDD {&beta}: `Breg';"         ///
            "Effective number of observations: `N'.")

            graph export "${graphs}\\`outcome'_`cohort'_`runvar'_bscatter_ages.png", ///
                replace width(1920) height(1080)

            local elig eligible_d
            local name day
        }
    }
}

        
log close

