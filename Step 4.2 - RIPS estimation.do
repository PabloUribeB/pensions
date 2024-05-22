/*************************************************************************
 *************************************************************************			       	
				RIPS estimation
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: May 21, 2024

3) Objective: Perform annual estimations for health outcomes across
			  cohorts

4) Output:	- RIPS_results.dta
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

global outcomes service consul proce urg hosp nro_servicios nro_consultas 	///
nro_procedimientos nro_urgencias nro_Hospitalizacion cons_psico estres 		///
cardiovascular infarct pre_MWI chronic


capture log close

log	using "$logs\RIPS estimations.smcl", replace


****************************************************************************
**# 		Estimations
****************************************************************************

local replace replace
forval year = 2009/2020 { // Loop through all years
	
	use if year_RIPS == `year' using "$data\RIPS_balanced_annual.dta", clear // Only use that year (faster)
	
	* Process raw data to create relevant variables
	quietly{
		
		rename (nro_serviciosHospitalizacion nro_serviciosurgencias nro_serviciosprocedimientos nro_serviciosconsultas) (nro_Hospitalizacion nro_urgencias nro_procedimientos nro_consultas)
		
		egen nro_servicios = rowtotal(nro_Hospitalizacion nro_urgencias nro_procedimientos nro_consultas)
		
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

		keep $outcomes poblacion* year_RIPS std_weeks // For efficiency
	}
	
	
	* First cohorts (M50 & F55) retire in 2010, so only one year before and after
	if inrange(`year', 2009, 2011){
		
		foreach cohort in $first_cohorts{
		
			foreach outcome in $outcomes{
					
				rdrobust `outcome' std_weeks if poblacion_`cohort' == 1 & 	///
				year_RIPS == `year', vce(cluster std_weeks)

				mat beta = e(tau_bc)			// Store robust beta
				mat vari = e(se_tau_rb) ^ 2		// Store robust SE

				* Save estimation results in dataset
				regsave using "${tables}/RIPS_results.dta", `replace' 			///
				coefmat(beta) varmat(vari) ci level(95) 						///
				addlabel(outcome, `outcome', cohort, `cohort', year, `year')
				
				local replace append
			}
		}
	}
	
	* Second cohorts (M54 & F59) retire in Dec. 2014, so 6 years pre and 6 post.
	* This loop happens for all years in the loop (2009/2020)
	foreach cohort in $second_cohorts{
		
		foreach outcome in $outcomes{
				
			rdrobust `outcome' std_weeks if poblacion_`cohort' == 1 & 		///
			year_RIPS == `year', vce(cluster std_weeks)

			mat beta = e(tau_bc)				// Store robust beta
			mat vari = e(se_tau_rb) ^ 2			// Store robust SE

			* Save estimation results in dataset
			regsave using "${tables}/RIPS_results.dta", append coefmat(beta) 	///
			varmat(vari) ci level(95) addlabel(outcome, `outcome', cohort, 		///
			`cohort', year, `year')
		}
	}
}

log close
