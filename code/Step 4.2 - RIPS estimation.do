/*************************************************************************
 *************************************************************************			       	
				PILA estimation
			 
1) Created by: Pablo Uribe
			   DIME - World Bank
			   puribebotero@worldbank.org
				
2) Date: May 21, 2024

3) Objective: Perform estimations for the health outcomes

4) Output:	- RIPS_results.dta
            - `outcome'_`cohort'_`bw'.png
*************************************************************************
*************************************************************************/	
clear all

****************************************************************************
*		Global directory, parameters and assumptions:
****************************************************************************

global cohorts M50 F55 M54 F59

global extensive service consul proce urg hosp cons_psico estres 		///
cardiovascular infarct chronic diag_mental

global intensive nro_servicios nro_consultas nro_procedimientos 		///
nro_urgencias nro_Hospitalizacion

global outcomes $extensive pre_MWI $intensive

set scheme white_tableau
set graphics off

capture log close

log	using "${logs}\RIPS estimations.smcl", replace


****************************************************************************
**#                 1. Estimations for each age
****************************************************************************

local replace replace
foreach cohort in $cohorts{
	
	use if (poblacion_`cohort' == 1) using "${data}\Estimation_sample_RIPS.dta", clear // Only use that cohort (faster)
	
	* Process raw data to create relevant variables
	quietly{
		
		rename (nro_serviciosHospitalizacion nro_serviciosurgencias 			///
		nro_serviciosprocedimientos nro_serviciosconsultas) 					///
		(nro_Hospitalizacion nro_urgencias nro_procedimientos nro_consultas)
		
		egen nro_servicios = rowtotal(nro_Hospitalizacion nro_urgencias 		///
		nro_procedimientos nro_consultas)

		keep $outcomes poblacion* age std_weeks // For efficiency
	}
	
	qui sum age if poblacion_`cohort' == 1
	local min = r(min)
	local max = r(max)
	
	forval age = `min'/`max'{
	
		foreach outcome in $outcomes{
			
			foreach bw in 11 22{ // Arbitrary bandwidth choices
				
				qui sum `outcome' if age == `age' & inrange(std_weeks, -`bw', -1)
				local control_mean = r(mean)
				
				dis as err "Regression for `outcome' with BW `bw' in cohort `cohort' for age `age'"
				
				rdrobust `outcome' std_weeks if	age == `age', 		///
				vce(cluster std_weeks) h(`bw') b(`bw')

				mat beta = e(tau_bc)			// Store robust beta
				mat vari = e(se_tau_rb) ^ 2		// Store robust SE

				local N_left = e(N_b_l)
				local N_right = e(N_b_r)
				
				* Save estimation results in dataset
				regsave using "${output}/RIPS_results.dta", `replace' 			///
				coefmat(beta) varmat(vari) ci level(95) 						///
				addlabel(outcome, `outcome', cohort, `cohort', age, `age', 		///
				bw, `bw', control, `control_mean', N_right, `N_right', N_left, `N_left')
				
				local replace append
			}
		}
	}
}


****************************************************************************
**#       2. Estimations with cumulative outcomes after retirement age
****************************************************************************

local replace replace
foreach cohort in $cohorts{
	
	if inlist("`cohort'", "M50", "M54"){
		local retire = 60
	}
	else{
		local retire = 55
	}
	
	use if (poblacion_`cohort' == 1) using "${data}\Estimation_sample_RIPS.dta", clear // Only use that cohort (faster)

	keep if age >= `retire'

	* Process raw data to create relevant variables
	quietly{
		
		rename (nro_serviciosHospitalizacion nro_serviciosurgencias 			///
		nro_serviciosprocedimientos nro_serviciosconsultas) 					///
		(nro_Hospitalizacion nro_urgencias nro_procedimientos nro_consultas)
		
		egen nro_servicios = rowtotal(nro_Hospitalizacion nro_urgencias 	///
		nro_procedimientos nro_consultas)
		
		labvars cardiovascular chronic cons_psico consul estres hosp infarct 	///
		nro_Hospitalizacion nro_consultas nro_procedimientos nro_servicios 		///
		nro_urgencias pre_MWI proce service urg diag_mental 					///
		"Cardiovascular" "Chronic disease" "Consultation with psychologist" 	///
		"Probability of consultation" "Stress" "Probability of hospitalization" ///
		"Infarct" "Number of hospitalizations" "Number of consultations" 		///
		"Number of procedures" "Number of services" "Number of ER visits" 		///
		"Multi-morbidity index" "Probability of procedures" 					///
		"Probability of health service" "Probability of ER visit" "Mental diagnosis"

		keep $outcomes poblacion* age std_weeks personabasicaid // For efficiency
		
		foreach var in ${extensive}{
			bys personabasicaid: ereplace `var' = max(`var')
		}
		
		foreach var in ${intensive}{
			bys personabasicaid: ereplace `var' = sum(`var')
		}
		
		bys personabasicaid: ereplace pre_MWI = min(pre_MWI)
		
		gduplicates drop personabasicaid, force
	}

	
	foreach outcome in $outcomes{
		
		if inlist("`outcome'", "nro_servicios", "nro_consultas", 		///
		"nro_procedimientos", "nro_urgencias", "nro_Hospitalizacion"){
			local dec = 2
			local title "Number"
		}
		else if "`outcome'" == "pre_MWI"{
			local dec = 2
			local title "Index"
		}
		else{
			local dec = 3
			local title "Percentage"
		}
		
		local varlab: variable label `outcome'
		
		foreach bw in 11 22{ // Arbitrary bandwidth choices
			
			qui sum `outcome' if inrange(std_weeks, -`bw', -1)
			local control_mean: dis %010.`dec'fc r(mean)
			
			dis as err "Regression for `outcome' with BW `bw' in cohort `cohort'"
			
			qui rdrobust `outcome' std_weeks, 				///
			vce(cluster std_weeks) h(`bw') b(`bw')
			
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
			
			rdplot `outcome' std_weeks if inrange(std_weeks,-`bw',`bw'), 		///
			vce(cluster std_weeks) p(1) kernel(triangular) h(`bw' `bw') 		///
			binselect(esmv) ci(95) shade										///
			graph_options(title(`varlab', size(medium)) 						///
			subtitle(Cohort: `cohort'; Weeks around cutoff: `bw', size(small)) 	///
			xtitle(Distance to week of birth's cutoff) ytitle(`title') 			///
			legend(rows(1) position(bottom)) ylabel(, format(%010.`dec'fc)) 	///
			note("Rdrobust coefficient: `B'. Control's mean: `control_mean'; Effective number of observations: `N'."))
			
			
			graph export "${graphs}\\`outcome'_`cohort'_`bw'.png", replace  ///
                width(1920) height(1080)
			
			local replace append
		}
	}
}

log close
