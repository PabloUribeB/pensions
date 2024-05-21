/*************************************************************************
 *************************************************************************			       	
				PILA estimation
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: May 21, 2024

3) Objective: Perform monthly estimations for labor market outcomes across
			  cohorts

4) Output:	- PILA_results.dta
*************************************************************************
*************************************************************************/	


****************************************************************************
*		Global directory, parameters and assumptions:
****************************************************************************

if "`c(hostname)'" == "SM201439"{
	global pc "C:"
}

else {
	global pc "\\sm093119"
}

global data 		"${pc}\Proyectos\Banrep research\Pensions\Data"
global tables 		"${pc}\Proyectos\Banrep research\Pensions\Tables"
global graphs 		"${pc}\Proyectos\Banrep research\Pensions\Graphs"
global data_master 	"${pc}\Proyectos\PILA master"
global logs 		"${pc}\Proyectos\Banrep research\Pensions\Logs"

global first_cohorts M50 F55
global second_cohorts M54 F59
global outcomes codigo_pension colpensiones pila_salario_r pila_salario_r_0


capture log close

log	using "$logs\PILA estimations.smcl", replace


****************************************************************************
**# 		Estimations
****************************************************************************

local replace replace
forval year = 2009/2020 { // Loop through all years
	
	use if year == `year' using "$data\mensual_PILA", clear // Only use that year (faster)

	/* If age is needed to impose restrictions
	tempvar dia_pila
	gen `dia_pila' = dofm(fecha_pila + 1) - 1
	format %td `dia_pila'

	gen age = age(fechantomode,`dia_pila')
	*/
	
	* Process raw data to create relevant variables
	quietly{
		
		gen poblacion_M50 = 1 if sexomode == 1 & inrange(fechantomode, -4383, -2557)
		gen poblacion_M54 = 1 if sexomode == 1 & inrange(fechantomode, -2922, -1096)
		gen poblacion_F55 = 1 if sexomode == 0 & inrange(fechantomode, -2556, -731)
		gen poblacion_F59 = 1 if sexomode == 0 & inrange(fechantomode, -1095, 730)

		foreach var of varlist poblacion* {
			replace `var' = 0 if mi(`var')
		}

		* Generate cutoff points for each cohort
		gen 	corte = -3441 if poblacion_M50 == 1
		replace corte = -1827 if poblacion_M54 == 1
		replace corte = -1615 if poblacion_F55 == 1
		replace corte = -1 	  if poblacion_F59 == 1

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

		keep $outcomes poblacion* year month std_weeks fecha_pila // For efficiency
	}
	
	
	* First cohorts (M50 & F55) retire in 2010, so only one year before and after
	if inrange(`year', 2009, 2011){
		
		foreach cohort in $first_cohorts{
		
			foreach outcome in $outcomes{
				
				forval month = 1/12{
					
					rdrobust `outcome' std_weeks if poblacion_`cohort' == 1 & 	///
					fecha_pila == ym(`year',`month'), vce(cluster std_weeks)

				mat beta = e(tau_bc)			// Store robust beta
				mat vari = e(se_tau_rb) ^ 2		// Store robust SE

				* Save estimation results in dataset
				regsave using "${tables}/PILA_results.dta", `replace' 			///
				coefmat(beta) varmat(vari) ci level(95) 						///
				addlabel(outcome, `outcome', cohort, `cohort', year, `year', month, `month')
				
				local replace append
				}
			}
		}
	}
	
	* Second cohorts (M54 & F59) retire in Dec. 2014, so 6 years pre and 6 post.
	* This loop happens for all years in the loop (2009/2020)
	foreach cohort in $second_cohorts{
		
		foreach outcome in $outcomes{
			
			forval month = 1/12{
				
				rdrobust `outcome' std_weeks if poblacion_`cohort' == 1 & 		///
				fecha_pila == ym(`year',`month'), vce(cluster std_weeks)

			mat beta = e(tau_bc)				// Store robust beta
			mat vari = e(se_tau_rb) ^ 2			// Store robust SE

			* Save estimation results in dataset
			regsave using "${tables}/PILA_results.dta", append coefmat(beta) 	///
			varmat(vari) ci level(95) addlabel(outcome, `outcome', cohort, 		///
			`cohort', year, `year', month, `month')
			}
		}
	}
}

log close

/* Risk dummies. There are 5 categories of risk with the following percentages:

		1. 0.522%
		2. 1.044%
		3. 2.436%
		4. 4.350%
		5. 6.960%
	
	Since rates are not precise in PILA, dummies are created to allow little
	deviations from these percentages, in order to capture the relevant risk
	category.


gen riesgo_na = (mi(tasa_riesgop))
gen riesgo_1 = (inrange(tasa_riesgop,0.002,0.007))
gen riesgo_2 = (inrange(tasa_riesgop,0.008,0.015))
gen riesgo_3 = (inrange(tasa_riesgop,0.020,0.030))
gen riesgo_4 = (inrange(tasa_riesgop,0.039,0.048))
gen riesgo_5 = (inrange(tasa_riesgop,0.064,0.075))

* Diagnostic
count if tasa_riesgop > 0.071


gen pension_tiempo = (pension == 1 & ((inrange(age,60,61) & sexomode == 1) | (inrange(age,55,56) & sexomode == 0)))

compress

******************
** Sample creation

** Sample: Individuals 1 year after retirement (whole year they have retirement age)
preserve

keep if (age == 60 & sexomode == 1) | (age == 55 & sexomode == 0)


* Formality dummies

tempvar cotiza
gen `cotiza' = (pila_dependientes == 1 | pila_independientes == 1)

tempvar nro_meses
gegen `nro_meses' = sum(`cotiza'), by(personabasicaid)

gen formalidad_3mes = (`nro_meses' >= 3)
gen formalidad_6mes = (`nro_meses' >= 6)


collapse (firstnm) sexomode fechantomode age poblacion* corte fechaweek corte_week std_weeks (sum) sal_dias_cot (max) riesgo* pension* pila_dependientes pila_independientes formalidad_* (mean) pila_salario_mes_r, by(personabasicaid)

tempfile oneyear
save `oneyear', replace

restore


** Sample: Individuals 2 years after retirement
preserve

keep if (inrange(age,60,61) & sexomode == 1) | (inrange(age,55,56) & sexomode == 0)


* Formality dummies

tempvar cotiza
gen `cotiza' = (pila_dependientes == 1 | pila_independientes == 1)

tempvar nro_meses
gegen `nro_meses' = sum(`cotiza'), by(personabasicaid)

gen formalidad_3mes = (`nro_meses' >= 3)
gen formalidad_6mes = (`nro_meses' >= 6)


collapse (firstnm) sexomode fechantomode age poblacion* corte fechaweek corte_week std_weeks (sum) sal_dias_cot (max) riesgo* pension* pila_dependientes pila_independientes formalidad_* (mean) pila_salario_mes_r, by(personabasicaid)

tempfile twoyears
save `twoyears', replace

restore


** Sample: Individuals 3 years after retirement
preserve

keep if (inrange(age,60,62) & sexomode == 1) | (inrange(age,55,57) & sexomode == 0)


* Formality dummies

tempvar cotiza
gen `cotiza' = (pila_dependientes == 1 | pila_independientes == 1)

tempvar nro_meses
gegen `nro_meses' = sum(`cotiza'), by(personabasicaid)

gen formalidad_3mes = (`nro_meses' >= 3)
gen formalidad_6mes = (`nro_meses' >= 6)


collapse (firstnm) sexomode fechantomode age poblacion* corte fechaweek corte_week std_weeks (sum) sal_dias_cot (max) riesgo* pension* pila_dependientes pila_independientes formalidad_* (mean) pila_salario_mes_r, by(personabasicaid)

tempfile threeyears
save `threeyears', replace

restore


** Sample: Individuals 5 years after retirement

keep if (inrange(age,60,64) & sexomode == 1) | (inrange(age,55,59) & sexomode == 0)


* Formality dummies

tempvar cotiza
gen `cotiza' = (pila_dependientes == 1 | pila_independientes == 1)

tempvar nro_meses
gegen `nro_meses' = sum(`cotiza'), by(personabasicaid)

gen formalidad_3mes = (`nro_meses' >= 3)
gen formalidad_6mes = (`nro_meses' >= 6)


collapse (firstnm) sexomode fechantomode age poblacion* corte fechaweek corte_week std_weeks (sum) sal_dias_cot (max) riesgo* pension* pila_dependientes pila_independientes formalidad_* (mean) pila_salario_mes_r, by(personabasicaid)

append using `threeyears' `twoyears' `oneyear', gen(samples_PILA)

label drop _append

label define _append 0 "Five years" 1 "Three years" 2 "Two years" 3 "One year", replace
label val samples_PILA _append

compress

save "$data\Estimation_samples_PILA.dta", replace


log close