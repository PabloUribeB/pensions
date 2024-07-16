		   ********************************************************
    	  /*           Master individual database	            */
		 /*             Creation date: 08/02/23         	   */
		/*            Last modification: 27/06/23     	      */
	   /*			 Author: Naomi Calle y Pablo Uribe	 	 */
	  ********************************************************


* This Do file matches the master dataset with RIPS and creates the relevant outcomes

* Working directory
if "`c(hostname)'" == "SM201439"{
	global data "C:\Proyectos\Banrep research\Pensions\Data"
	global tables "C:\Proyectos\Banrep research\Pensions\Tables"
	global graphs "C:\Proyectos\Banrep research\Pensions\Graphs"
	global data_master "C:\Proyectos\PILA master"
	global urgencias "C:\Proyectos\Banrep research\More_than_a_Healing\Data"
}

else {
	global data "\\sm093119\Proyectos\Banrep research\Pensions\Data"
	global tables "\\sm093119\Proyectos\Banrep research\Pensions\Tables"
	global graphs "\\sm093119\Proyectos\Banrep research\Pensions\Graphs"
	global data_master "\\sm093119\Proyectos\PILA master"
	global urgencias "\\sm093119\Proyectos\Banrep research\More_than_a_Healing\Data"
}


use if inrange(std_weeks, -22, 22) using "$data\Merge_individual_RIPS.dta", clear

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
	gen respiratory_`i' = (substr(`d', 1, 3) == "T71" 				///
	| `d' == "T780" | `d' == "T782" | substr(`d', 1, 3) == "J96" 	///
	| `d' == "R092" | substr(`d', 1, 3) == "J80" 					///
	| substr(`d', 1, 3) == "J81" | substr(`d', 1, 3) == "J81X" 		///
	| substr(`d', 1, 3) == "J681"| substr(`d', 1, 3) == "W840" 		///
	| substr(`d', 1, 3) == "T670")

	*Trauma
	gen trauma_`i' = (`d' == "S097" | `d' == "S270" | `d' == "S219" ///
	| `d' == "S062" | `d' == "S065" | `d' == "S066" | `d' == "V299" ///
	| `d' == "I711" | `d' == "S299" |`d' == "S127" | `d' == "T794" 	///
	| `d' == "S063" | `d'== "Y200" | `d' == "S357" | `d' == "X941" 	///
	| `d' == "T1791" | `d' == "T1790" | `d' == "T060.0" 			///
	| substr(`d', 1, 3) == "T06" | substr(`d', 1, 3) == "S14" 		///
	| substr(`d', 1, 3) == "S06" | substr(`d', 1, 3) == "T07")

	*Stroke
	gen stroke_`i' = (substr(`d', 1, 3) == "I61" 					///
	| substr(`d', 1, 3) == "I60" | substr(`d', 1, 3) == "I64" 		///
	| substr(`d', 1, 3) == "I63" |`d' == "G934" |`d' == "G935" 		///
	| `d' == "G936" | `d' == "S062" | `d' == "S065" | `d' == "E104" ///
	| `d' == "G412" | `d' == "I638" | `d' == "S066" | `d' == "P294" ///
	| `d' == "G464" |`d' == "G407" | `d' == "R568")

	*Infarcts
	gen infarct_`i' = (substr(`d', 1, 3) == "I20" 					///
	| substr(`d', 1, 3) == "I21" | substr(`d', 1, 3) == "I22" 		///
	| substr(`d', 1, 3) == "I23" | substr(`d', 1, 3) == "I24" 		///
	| substr(`d', 1, 3) == "I25")

	*Cardiovascular
	gen cardiovascular_`i' = (substr(`d', 1, 3)== "I46" | substr(`d', 1, 3)== "I50")


	gen diag_laboral_`i' = ((substr(`d',1,3)=="R53") 				///
	| (substr(`d',1,3)=="Y96") | (substr(`d',1,3)=="Z56") 			///
	| (substr(`d',1,3)=="Z57") | (substr(`d',1,4)=="Z732"))

	gen diag_mental_`i'	= (substr(substr(`d', 1, 3),1,1) == "F")

	gen estres_`i' = ((substr(`d',1,2)=="F3") 						///
	| (substr(`d',1,2)=="F4") | (substr(`d',1,4)=="Z563") 			///
	| (substr(`d',1,4)=="Z637") | (substr(`d',1,4)=="Z733"))

	gen estres_laboral_`i' = ((substr(`d',1,4)=="F480") 			///
	| (substr(`d',1,4)=="F488") | (substr(`d',1,4)=="Z563"))

	gen covid_`i' = ((substr(`d',1,4)=="U071") | (substr(`d',1,4)=="U072"))
	
	gen covid_related_`i' = (covid_`i' == 1 | (substr(`d',1,4)=="R092") ///
	| (substr(`d',1,4)=="J960") | (substr(`d',1,4)=="J969") 		///
	| (substr(`d',1,4)=="U109") | (substr(`d',1,4)=="U049"))

	local i = `i' + 1

}

foreach var in sepsis respiratory trauma stroke cardiovascular infarct diag_laboral diag_mental estres estres_laboral covid covid_related{
	
	egen `var' = rowmax(`var'_1 `var'_2 `var'_3 `var'_4)
	
	drop `var'_1 `var'_2 `var'_3 `var'_4
	
}

gen time_sensitive = (sepsis == 1 | respiratory == 1 | trauma == 1 | stroke == 1)

***** Work-related afflictions and stress

gen accidente_laboral  	= (causa_externa==1)

gen enfermedad_laboral 	= (causa_externa==14)

gen acc_enf_laboral		= (accidente_laboral == 1 | enfermedad_laboral == 1)

gen cons_psico 			= (substr(cod_consul,5,2)=="08")

gen cons_trab_social 	= (substr(cod_consul,5,2)=="09")

gen cons_psiquiatra 	= (substr(cod_consul,5,2)=="84")

gen cons_mental 		= (cons_psico == 1 | cons_psiquiatra == 1 | cons_trab_social == 1)


global t_sensitive time_sensitive sepsis respiratory trauma stroke cardiovascular infarct

global work accidente_laboral enfermedad_laboral acc_enf_laboral cons_psico cons_trab_social cons_psiquiatra cons_mental diag_laboral estres estres_laboral diag_mental

gen contador = 1

compress

* Count number of health services by age and keep one observation per person and age
bys personabasicaid age service: gegen nro_servicios = total(contador)

** Replace all values for each person in a given age with the maximum value (1 if happens at that age)
foreach variable in $t_sensitive $work{
    dis as err "Creating variable for `variable'"
	bys personabasicaid age: ereplace `variable' = max(`variable')
}

keep personabasicaid age service nro_servicios $t_sensitive $work poblacion* std_weeks

compress

gduplicates drop personabasicaid age service, force

greshape wide nro_servicios, i(personabasicaid age) j(service) string


fillin personabasicaid age

foreach var of varlist nro_serviciosHospitalizacion-cons_mental {
	replace `var' = 0 if mi(`var')
}

compress
save "$data\personabasicaid_age_RIPS.dta", replace	



********************************************************************************
**#      Merge with Chronic diseases to get comorbidity index weights      
********************************************************************************
use "$urgencias\Crosswalk_chronic_diseases", clear

gen diag_prin = substr(icd10cm, 1, 4)
keep diag_prin organ_system no_diagnosis diagnosis MWI_weight

gen diag_r1 = diag_prin
gen diag_r2 = diag_prin
gen diag_r3 = diag_prin

gduplicates drop diag_prin, force

tempfile temp_chronic_diseases
save `temp_chronic_diseases', replace


use if inrange(std_weeks, -22, 22) using "$data\Merge_individual_RIPS.dta", clear

drop diag_prin_ingre cod_diag_prin

* Get chronic weights for each of diagnosis variables
local x = 1
foreach diag in diag_prin diag_r1 diag_r2 diag_r3 {
	merge m:1 `diag' using `temp_chronic_diseases', keepusing(`diag' MWI_weight no_diagnosis) keep(1 3) gen(merge_d`x')
	rename (MWI_weight no_diagnosis) (MWI_weight_`x' no_diagnosis_`x')
	
	local x = `x' + 1
}

gen chronic = merge_d1 == 3 | merge_d2 == 3 | merge_d3 == 3 | merge_d4 == 3
lab var chronic "Has chronic disease diagnosis (1)"

drop merge_*


********************************************************************************
**#                   Generate multimorbidity index                            *
********************************************************************************
/* We are now using all the diagnoses variables to build the index, so in order to
   not double-count diagnoses we have to establish the first time we see a diagnosis
   within the window of interest. For that, we put all diagnoses into a single
   variable */
   
gen age = age(fechantomode,date)
keep if (inrange(age, 59, 71) & poblacion_M50 == 1) | 			///
		(inrange(age, 54, 66) & poblacion_F55 == 1) | 			///
		(inrange(age, 55, 67) & poblacion_M54 == 1) | 			///
		(inrange(age, 50, 62) & poblacion_F59 == 1)

sort personabasicaid age

* Keep only people with chronic diagnosis
keep if chronic == 1

* Append different diagnosis variables into the same one
preserve

clear all
gen aux = .
tempfile temp_diags
save `temp_diags', replace

restore

forval i = 1/4{
	
   preserve
   
	keep personabasicaid age chronic MWI_weight_`i' no_diagnosis_`i'
	
	rename (no_diagnosis_`i' MWI_weight_`i') (no_diagnosis MWI_weight)

	append using `temp_diags'
	save `temp_diags', replace
	
	restore
}

use `temp_diags', clear

* The related diagnoses have too many missing values. We can drop them because we already know that any of the other diagnoses in that observation were chronic before the append 
drop if mi(no_diagnosis)


* Multimorbidity Weighted Index
bys personabasicaid no_diagnosis age: gen n_pre = _n if chronic == 1
bys personabasicaid age: gegen N_pre = max(n_pre)

bys personabasicaid age: gegen pre_MWI = sum(MWI_weight) if chronic == 1 & n_pre == N_pre

rename N_pre nro_chronic

* Paste chronic and MWI variables by personabasicaid
bys personabasicaid age: ereplace chronic = max(chronic)
bys personabasicaid age: ereplace pre_MWI = max(pre_MWI)

keep personabasicaid pre_* age chronic nro_chronic

gduplicates drop personabasicaid age, force

tempfile temp_MWI_chronic
save `temp_MWI_chronic', replace

* Paste the index and chronic variables to master balanced
use "$data\personabasicaid_age_RIPS.dta", clear

merge 1:1 personabasicaid age using `temp_MWI_chronic', keep(1 3) nogen

gen proce = nro_serviciosprocedimientos > 0
gen consul = nro_serviciosconsultas > 0 
gen urg = nro_serviciosurgencias > 0 
gen hosp = nro_serviciosHospitalizacion > 0
gen service = nro_serviciosprocedimientos > 0 | nro_serviciosconsultas > 0 | nro_serviciosurgencias > 0 | nro_serviciosHospitalizacion > 0
gen consul_proce = nro_serviciosprocedimientos > 0 | nro_serviciosconsultas > 0
gen urg_hosp = nro_serviciosurgencias > 0 | nro_serviciosHospitalizacion > 0

replace chronic = 0 if chronic == .
replace nro_chronic = 0 if mi(nro_chronic)

gen cohort = 1 if poblacion_M50 == 1
replace cohort = 2 if poblacion_F55 == 1
replace cohort = 3 if poblacion_M54 == 1
replace cohort = 4 if poblacion_F59 == 1

gen abso_mwi = abs(pre_MWI)

bys cohort: egen median_MWI = median(abso_mwi)

gen ab50_chronic = (abs(pre_MWI) > median_MWI & mi(pre_MWI) == 0)
gen be50_chronic = (abs(pre_MWI) < median_MWI & mi(pre_MWI) == 0)

local gen gen
forvalues i=1/4{
    sum abso_mwi if cohort == `i', d
	local 75_m50 = r(p75)
	local 25_m50 = r(p25)
	`gen' ab75_chronic = 1 if abs(pre_MWI) > `75_m50' & cohort == `i' & mi(pre_MWI) == 0
	`gen' be25_chronic = 1 if abs(pre_MWI) < `25_m50' & cohort == `i' & mi(pre_MWI) == 0
	local gen replace
}

replace ab75_chronic = 0 if mi(ab75_chronic) & mi(pre_MWI) == 0
replace be25_chronic = 0 if mi(be25_chronic) & mi(pre_MWI) == 0

drop cohort median_MWI abso_mwi

keep if (inrange(age, 59, 71) & poblacion_M50 == 1) | 			///
		(inrange(age, 54, 66) & poblacion_F55 == 1) | 			///
		(inrange(age, 55, 67) & poblacion_M54 == 1) | 			///
		(inrange(age, 50, 62) & poblacion_F59 == 1)

compress

save "${data}\Estimation_sample_RIPS.dta", replace

erase "$data\personabasicaid_age_RIPS.dta"
