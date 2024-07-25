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
clear all

****************************************************************************
*		Global directory, parameters and assumptions:
****************************************************************************

global first_cohorts M50 F55
global second_cohorts M54 F59
global outcomes codigo_pension colpensiones pila_salario_r pila_salario_r_0


capture log close

log	using "${logs}\PILA estimations.smcl", replace


****************************************************************************
**# 		1. Estimations
****************************************************************************

local replace replace
forval year = 2009/2020 { // Loop through all years
	
	use if year == `year' using "${data}\mensual_PILA", clear // Only use that year (faster)

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
				regsave using "${output}/PILA_results.dta", `replace' 			///
				coefmat(beta) varmat(vari) ci level(95) 						///
				addlabel(outcome, `outcome', cohort, `cohort', year, `year',    ///
                month, `month')
				
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
			regsave using "${output}/PILA_results.dta", append coefmat(beta) 	///
			varmat(vari) ci level(95) addlabel(outcome, `outcome', cohort, 		///
			`cohort', year, `year', month, `month')
			}
		}
	}
}

log close
