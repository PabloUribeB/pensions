/*************************************************************************
 *************************************************************************
                    Summary Stats

1) Created by: Pablo Uribe
               Yale University
               p.uribe@yale.edu

2) Date: July 17 2025

3) Objective: Plot histograms and perform density tests
           
4) Output:    - hist.png for each cohort
              - summary_stats.tex
              - numbers.tex

*************************************************************************
*************************************************************************/
clear all

****************************************************************************
* Globals
****************************************************************************

set scheme white_tableau

global extensive service consul proce urg hosp cardiovascular estreslaboral msk

global all_outcomes wage pension servicios consultas proced urgencias ///
       hospits $extensive

capture log close

log	using "${logs}/Summary stats.smcl", replace

****************************************************************************
**#         1. Get main N
****************************************************************************

use "${data}/Master_sample.dta", clear

keep if poblacion_M50 == 1 | poblacion_F55 == 1

count

local total_n = strtrim("`: di %10.0fc r(N)'")

texresults3 using "${tables}/numbers.txt", texmacro(totalN)             ///
result(`total_n') append

****************************************************************************
**#         2. Plot histograms
****************************************************************************

use "${data}/Master_for_RIPS.dta", clear

count if poblacion_M50 == 1 | poblacion_F55 == 1

local master_n = strtrim("`: di %10.0fc r(N)'")

texresults3 using "${tables}/numbers.txt", texmacro(masterN)            ///
result(`master_n') append

count if poblacion_F55 == 1
local f55_n = strtrim("`: di %10.0fc r(N)'")

count if poblacion_M50 == 1
local m50_n = strtrim("`: di %10.0fc r(N)'")

* Histograms using roughly a bin per week (5 years * 52 weeks = 260)

* M50
qui rddensity std_weeks if poblacion_M50 == 1
local pvalue = e(pv_q)

texresults3 using "${tables}/numbers.txt", texmacro(pvalMw)            ///
result(`pvalue') append round(3)

qui rddensity std_days if poblacion_M50 == 1
local pvalue_d = e(pv_q)

texresults3 using "${tables}/numbers.txt", texmacro(pvalMd)            ///
result(`pvalue_d') append round(3)

twoway (hist fechantomode if poblacion_M50 == 1, xla(#15, angle(90)     ///
format("%td")) xtitle(Date of birth)      ///
bin(260) freq ylabel(, format(%10.0fc))),           ///
xline(-3441, noextend lcolor(red) lpattern(solid)) legend(off)

graph export "${graphs}/hist_M50.png", replace


/* M54
qui rddensity std_weeks if poblacion_M54 == 1
local pvalue: dis %04.3f e(pv_q)

qui rddensity std_days if poblacion_M54 == 1
local pvalue_d: dis %04.3f e(pv_q)

twoway (hist fechantomode if poblacion_M54 == 1, xla(#15, angle(90)     ///
format("%td")) xtitle(Date of birth) title(Men born between 52-56)      ///
note("Manipulation test p-value weeks: `pvalue'"                        ///
"Manipulation test p-value days: `pvalue_d'") bin(260) freq),           ///
xline(-1827, noextend lcolor(red) lpattern(solid)) legend(off)

graph export "${graphs}/hist_M54.png", replace
*/

* F55
qui rddensity std_weeks if poblacion_F55 == 1
local pvalue = e(pv_q)

texresults3 using "${tables}/numbers.txt", texmacro(pvalFw)            ///
result(`pvalue') append round(3)

qui rddensity std_days if poblacion_F55 == 1
local pvalue_d = e(pv_q)

texresults3 using "${tables}/numbers.txt", texmacro(pvalFd)            ///
result(`pvalue_d') append round(3)

twoway (hist fechantomode if poblacion_F55 == 1, xla(#15, angle(90)     ///
format("%td")) xtitle(Date of birth)   ///
bin(260) freq ylabel(, format(%10.0fc))),           ///
xline(-1615, noextend lcolor(red) lpattern(solid)) legend(off)

graph export "${graphs}/hist_F55.png", replace


/* F59
qui rddensity std_weeks if poblacion_F59 == 1
local pvalue: dis %04.3f e(pv_q)

qui rddensity std_days if poblacion_F59 == 1
local pvalue_d: dis %04.3f e(pv_q)

twoway (hist fechantomode if poblacion_F59 == 1, xla(#15, angle(90)     ///
format("%td")) xtitle(Date of birth) title(Women born between 57-61)    ///
note("Manipulation test p-value weeks: `pvalue'"                        ///
"Manipulation test p-value days: `pvalue_d'") bin(260) freq),           ///
xline(-1, noextend lcolor(red) lpattern(solid)) legend(off)

graph export "${graphs}/hist_F59.png", replace

*/


****************************************************************************
**#         3. Summary stats table
****************************************************************************


** PILA
use if (poblacion_M50 == 1 | poblacion_F55 == 1) using "${data}/Estimation_sample_PILA.dta", clear

replace pila_salario_r_0 = . if pila_salario_r_0 = 0

collapse (mean) pila_salario_r_0 ibc_pens (max) pension_ibc   ///
         (firstnm) poblacion*, by(personabasicaid)

rename (pila_salario_r_0 ibc_pens pension_ibc) (wage ibc pension)

local coh "M"
foreach cohort in M50 F55 {
    
    foreach outcome in wage ibc pension {
        
        if "`outcome'" == "pension" {
            local fmt "3"
            local add "*100"
            local rounded "round(1)"
        }
        else{
            local fmt "0"
            local add ""
            local rounded ""
        }
        
        sum `outcome' if poblacion_`cohort' == 1
        local m_`outcome'_`cohort'   : di %13.`fmt'fc r(mean)
        local sd_`outcome'_`cohort'  : di %13.`fmt'fc r(sd)
        local min_`outcome'_`cohort' : di %13.0fc r(min)
        local max_`outcome'_`cohort' : di %13.0fc r(max)
        
        local `outcome'_`cohort': di %10.`fmt'fc r(mean)`add'

        texresults3 using "${tables}/numbers.txt", texmacro(`outcome'`coh')  ///
        result(``outcome'_`cohort'') append `rounded'
    }
    
    _pctile wage if poblacion_`cohort' == 1, p(99)
    local max_wage_`cohort' : di %13.0fc r(r1)
    local coh "F"
}





** RIPS
use if (poblacion_M50 == 1 | poblacion_F55 == 1) using              ///
       "${data}/Estimation_sample_RIPS.dta", clear

rename (nro_serviciosHospitalizacion nro_serviciosurgencias                     ///
    nro_serviciosprocedimientos nro_serviciosconsultas estres_laboral)          ///
    (nro_Hospitalizacion nro_urgencias nro_procedimientos nro_consultas         ///
    estreslaboral)
    
egen nro_servicios = rowtotal(nro_Hospitalizacion nro_urgencias         ///
    nro_procedimientos nro_consultas)
       
collapse (sum) nro* (max) $extensive   ///
         (firstnm) poblacion*, by(personabasicaid)

rename (nro_servicios nro_consultas nro_procedimientos nro_urgencias    ///
        nro_Hospitalizacion) (servicios consultas proced urgencias hospits)
  
local coh "M"
foreach cohort in M50 F55 {
    
    foreach outcome in servicios consultas proced urgencias hospits {
        
        if inlist("`outcome'", "urgencias", "hospits") {
            local rounded "round(1)"
        }
        else{
            local rounded "round(0)"
        }
        
        sum `outcome' if poblacion_`cohort' == 1
        local m_`outcome'_`cohort'   : di %10.3fc r(mean)
        local sd_`outcome'_`cohort'  : di %10.3fc r(sd)
        local min_`outcome'_`cohort' : di %10.3fc r(min)
        _pctile wage if poblacion_`cohort' == 1, p(99)
        local max_`outcome'_`cohort' : di %13.0fc r(r1)
        
        local `outcome'_`cohort' = strtrim("`: di r(mean)'")
    
        texresults3 using "${tables}/numbers.txt", texmacro(`outcome'`coh')  ///
        result(``outcome'_`cohort'') append `rounded'
    }
    local coh "F"
}


local coh "M"
foreach cohort in M50 F55 {
    
    foreach outcome in $extensive {
        
        sum `outcome' if poblacion_`cohort' == 1
        local m_`outcome'_`cohort'   : di %10.3fc r(mean)
        local sd_`outcome'_`cohort'  : di %10.3fc r(sd)
        local min_`outcome'_`cohort' : di %10.0fc r(min)
        local max_`outcome'_`cohort' : di %10.0fc r(max)
        
        local `outcome'_`cohort' = r(mean)*100

        texresults3 using "${tables}/numbers.txt", texmacro(`outcome'`coh')  ///
        result(``outcome'_`cohort'') append round(1)
    }
    local coh "F"
}

gen wage    = .
gen ibc     = .
gen pension = .

labvars $all_outcomes                                                            ///
    "Monthly real wage" "Pension proxy"                                          ///
    "Number of services" "Number of consultations" "Number of procedures"        ///
    "Number of ER visits" "Number of hospitalizations" "Any service" "Consulted" ///
    "Procedures" "Visited ER" "Hospitalized" "Cardiovascular"                    ///
    "Work-related stress" "Musculoskeletal disease"

* LaTex table
texdoc init "${tables}/summary_stats.tex", replace force

tex \begin{tabular}{lcccccccc}
tex \toprule

tex & \multicolumn{4}{c}{M50} & \multicolumn{4}{c}{F55} \\
tex \cmidrule(l){2-5} \cmidrule(l){6-9}

tex & Mean & SD & Min & Max & Mean & SD & Min & Max \\
tex \midrule



local i = 1
local j = 1
foreach var of global all_outcomes {
    
    local w: variable label `var'
    
    if `i' == 1       local panel "tex \multicolumn{9}{l}{\textit{Panel A: Labor market}} \\"
    else if `i' == 3  local panel "tex \multicolumn{9}{l}{\textit{Panel B: Health}} \\"
    else              local panel

    if `j' == 2       local space "\addlinespace"
    else              local space
    
    
    `panel'
    tex `w' & `m_`var'_M50' & `sd_`var'_M50' & `min_`var'_M50' & `max_`var'_M50' & `m_`var'_F55' & `sd_`var'_F55' & `min_`var'_F55' & `max_`var'_F55' \\ `space'

    local ++i
    local ++j
}

tex \midrule
tex Observations & \multicolumn{4}{c}{`m50_n'} & \multicolumn{4}{c}{`f55_n'} \\

tex \bottomrule
tex \end{tabular}
texdoc close



log close

