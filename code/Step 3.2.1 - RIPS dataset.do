/*************************************************************************
 *************************************************************************			       	
	        RIPS variable construction
			 
1) Created by: Pablo Uribe
			   Yale University
			   p.uribe@yale.edu
				
2) Date: April 2023

3) Objective: Create all health variables
           
4) Output:    - Estimation_sample_RIPS.dta

*************************************************************************
*************************************************************************/	
clear all

cap log close
log	using "${logs}/RIPS creation.smcl", replace

****************************************************************************
**#         1. Create RIPS variables
****************************************************************************

use "${data}/Merge_individual_RIPS.dta", clear

merge m:1 personabasicaid using "${data}/Master_for_RIPS.dta", nogen keep(3)

drop diag_prin_ingre fecha_ingreso cod_diag_prin fecha_consul

gen age = age(fechantomode,date)

keep if (inrange(age, 59, 71) & poblacion_M50 == 1) | 			///
		(inrange(age, 54, 66) & poblacion_F55 == 1) | 			///
		(inrange(age, 55, 67) & poblacion_M54 == 1) | 			///
		(inrange(age, 50, 62) & poblacion_F59 == 1)
		
drop date

*** Create variables by looping over diagnosis codes
local i = 1
foreach d in diag_prin diag_r1 diag_r2 diag_r3 {

***** Time-sensitive conditions

	*Sepsis
	gen sepsis_`i' = (`d' == "A419" | `d' == "P369" | `d' == "A427" ///
	| `d' == "T814" | `d'== "A415" | `d' == "A021" | `d' == "A154" 	///
	| `d' == "A482" | `d' == "R451" | `d' == "P378" | `d' == "A418" ///
	| `d' == "A548" | `d' == "P361" | `d' == "A418" | `d' == "O85X" ///
	| `d' == "A410" | `d' ==  "A403" | substr(`d', 1, 3) == "A40" 	///
	| substr(`d', 1, 3) == "A41" )

	*Respiratory
	gen respiratory_`i' = (substr(`d', 1, 3) == "T71"               ///
	| `d' == "T780" | `d' == "T782" | substr(`d', 1, 3) == "J96"    ///
	| `d' == "R092" | substr(`d', 1, 3) == "J80"                    ///
	| substr(`d', 1, 3) == "J81" | substr(`d', 1, 3) == "J81X"      ///
	| substr(`d', 1, 3) == "J681"| substr(`d', 1, 3) == "W840" 	    ///
	| substr(`d', 1, 3) == "T670")

	*Trauma
	gen trauma_`i' = (`d' == "S097" | `d' == "S270" | `d' == "S219" ///
	| `d' == "S062" | `d' == "S065" | `d' == "S066" | `d' == "V299" ///
	| `d' == "I711" | `d' == "S299" |`d' == "S127" | `d' == "T794" 	///
	| `d' == "S063" | `d'== "Y200" | `d' == "S357" | `d' == "X941" 	///
	| `d' == "T1791" | `d' == "T1790" | `d' == "T060.0"             ///
	| substr(`d', 1, 3) == "T06" | substr(`d', 1, 3) == "S14"       ///
	| substr(`d', 1, 3) == "S06" | substr(`d', 1, 3) == "T07")

	*Stroke
	gen stroke_`i' = (substr(`d', 1, 3) == "I61"                    ///
	| substr(`d', 1, 3) == "I60" | substr(`d', 1, 3) == "I64"       ///
	| substr(`d', 1, 3) == "I63" |`d' == "G934" |`d' == "G935"      ///
	| `d' == "G936" | `d' == "S062" | `d' == "S065" | `d' == "E104" ///
	| `d' == "G412" | `d' == "I638" | `d' == "S066" | `d' == "P294" ///
	| `d' == "G464" |`d' == "G407" | `d' == "R568")

	*Infarcts
	gen infarct_`i' = (substr(`d', 1, 3) == "I20"                   ///
	| substr(`d', 1, 3) == "I21" | substr(`d', 1, 3) == "I22"       ///
	| substr(`d', 1, 3) == "I23" | substr(`d', 1, 3) == "I24"       ///
	| substr(`d', 1, 3) == "I25")

	*Cardiovascular
	gen cardiovascular_`i' = (substr(`d', 1, 3)== "I46"             ///
    | substr(`d', 1, 3) == "I50")


	gen diag_laboral_`i' = ((substr(`d',1,3)=="R53")                ///
	| (substr(`d',1,3)=="Y96") | (substr(`d',1,3)=="Z56")           ///
	| (substr(`d',1,3)=="Z57") | (substr(`d',1,4)=="Z732"))

	gen diag_mental_`i'	= (substr(substr(`d', 1, 3),1,1) == "F")

	gen estres_laboral_`i' = ((substr(`d',1,4)=="F480")             ///
	| (substr(`d',1,4)=="F488") | (substr(`d',1,4)=="Z563"))

    *Depression
	gen depresion_`i' = (inlist(substr(`d',1,3),"F32","F33"))
	
	*Anxiety
	gen ansiedad_`i'  = (inlist(substr(`d',1,3),"F40","F41"))

	*Stress
	gen estres_`i'  = ((substr(`d',1,3)=="F43")   | (substr(`d',1,4)=="Z563") | ///
                       (substr(`d',1,4)=="Z637") | (substr(`d',1,4)=="Z733") )
    
    gen diag_mental2_`i' = (depresion_`i' == 1 | ansiedad_`i' == 1 |    ///
        estres_`i' == 1)
        
    gen msk_`i' = (inlist(substr(`d',1,3),"M54","M70","M75","M76","M77","M50","M51") | ///
                   inlist(substr(`d',1,4), "M255","M791","M796"))
                   
    gen hypertension_`i' = (substr(`d',1,2) == "I1")
    
	local i = `i' + 1

}

foreach var in sepsis respiratory trauma stroke cardiovascular infarct  ///
diag_laboral diag_mental diag_mental2 estres estres_laboral depresion   ///
ansiedad msk hypertension {
	
	egen `var' = rowmax(`var'_1 `var'_2 `var'_3 `var'_4)
	
	drop `var'_1 `var'_2 `var'_3 `var'_4
	
}

gen time_sensitive = (sepsis == 1 | respiratory == 1 | trauma == 1 | stroke == 1)

***** Work-related afflictions and stress

gen accidente_laboral   = (causa_externa==1)

gen enfermedad_laboral 	= (causa_externa==14)

gen acc_enf_laboral	    = (accidente_laboral == 1 | enfermedad_laboral == 1)

gen     cons_psico  = 1 if (substr(cod_consul, 5, 2) == "08" &          ///
                                    service == "consultas")
                                    
replace cons_psico  = 0 if (substr(cod_consul, 5, 2) != "08" &          ///
                                    service == "consultas")

                                    
gen     cons_trab_social = 1 if (substr(cod_consul, 5, 2) == "09" &     ///
                                    service == "consultas")
                                    
replace cons_trab_social = 0 if (substr(cod_consul, 5, 2) != "09" &     ///
                                    service == "consultas")

                                    
gen     cons_psiquiatra = 1 if (substr(cod_consul, 5, 2) == "84" &      ///
                                    service == "consultas")
                                    
replace cons_psiquiatra = 0 if (substr(cod_consul, 5, 2) != "84" &      ///
                                    service == "consultas")

gen cons_mental         = (cons_psico == 1 | cons_psiquiatra == 1 |     ///
                          cons_trab_social == 1)


global t_sensitive time_sensitive sepsis respiratory trauma stroke      ///
cardiovascular infarct

global work accidente_laboral enfermedad_laboral acc_enf_laboral        ///
cons_psico cons_trab_social cons_psiquiatra cons_mental diag_laboral    ///
estres estres_laboral diag_mental diag_mental2 depresion ansiedad msk hypertension

gen contador = 1

compress

* Count number of health services by age and keep one observation per person 
* and age
bys personabasicaid age service: gegen nro_servicios = total(contador)

** Replace all values for each person in a given age with the maximum value 
** (1 if happens at that age)
foreach variable in $t_sensitive $work {
    dis as err "Creating variable for `variable'"
	bys personabasicaid age: ereplace `variable' = max(`variable')
}

keep personabasicaid age service nro_servicios $t_sensitive $work   ///
    poblacion* std_weeks

compress

gduplicates drop personabasicaid age service, force

greshape wide nro_servicios, i(personabasicaid age) j(service) string


fillin personabasicaid age

foreach var of varlist nro_serviciosHospitalizacion-cons_mental {
	replace `var' = 0 if mi(`var')
}

foreach var of varlist poblacion* {
    bys personabasicaid: ereplace `var' = max(`var')
}

drop _fillin

gen proce = nro_serviciosprocedimientos > 0
gen consul = nro_serviciosconsultas > 0 
gen urg = nro_serviciosurgencias > 0 
gen hosp = nro_serviciosHospitalizacion > 0
gen service = nro_serviciosprocedimientos > 0 | nro_serviciosconsultas > 0 | ///
    nro_serviciosurgencias > 0 | nro_serviciosHospitalizacion > 0

gen consul_proce = nro_serviciosprocedimientos > 0 | nro_serviciosconsultas > 0
gen urg_hosp = nro_serviciosurgencias > 0 | nro_serviciosHospitalizacion > 0


keep if (inrange(age, 59, 71) & poblacion_M50 == 1) |           ///
        (inrange(age, 54, 66) & poblacion_F55 == 1) |           ///
        (inrange(age, 55, 67) & poblacion_M54 == 1) |           ///
        (inrange(age, 50, 62) & poblacion_F59 == 1)

compress

save "${data}/Estimation_sample_RIPS.dta", replace

* Sanity checks
mdesc poblacion* age

tab age if poblacion_M50 == 1, m
tab age if poblacion_F55 == 1, m

log close