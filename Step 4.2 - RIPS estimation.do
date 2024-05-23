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

cap which ereplace
if _rc ssc install ereplace

cap which labvars
if _rc ssc install labvars

global cohorts M50 F55 M54 F59

global extensive service consul proce urg hosp cons_psico estres 		///
cardiovascular infarct chronic diag_mental

global intensive  nro_servicios nro_consultas nro_procedimientos 		///
nro_urgencias nro_Hospitalizacion

global outcomes ${extensive} pre_MWI ${intensive}

set scheme white_tableau
set graphics off

capture log close

log	using "$logs\RIPS estimations.smcl", replace


****************************************************************************
**# 		Estimations for each age
****************************************************************************

local replace replace
foreach cohort in $cohorts{
	
	use if (poblacion_`cohort' == 1) using "$data\Estimation_sample_RIPS.dta", clear // Only use that cohort (faster)
	
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
				
				qui sum `outcome' if poblacion_`cohort' == 1 & age == `age' & ///
				inrange(std_weeks, -`bw', -1)
				local control_mean = r(mean)
				
				dis as err "Regression for `outcome' with BW `bw' in cohort `cohort' for age `age'"
				
				rdrobust `outcome' std_weeks if poblacion_`cohort' == 1 & 	///
				age == `age', vce(cluster std_weeks) h(-`bw' `bw') b(-`bw' `bw')

				mat beta = e(tau_bc)			// Store robust beta
				mat vari = e(se_tau_rb) ^ 2		// Store robust SE

				* Save estimation results in dataset
				regsave using "${tables}/RIPS_results.dta", `replace' 			///
				coefmat(beta) varmat(vari) ci level(95) 						///
				addlabel(outcome, `outcome', cohort, `cohort', age, `age', 		///
				bw, `bw', control, `control_mean')
				
				local replace append
			}
		}
	}
}


****************************************************************************
**# 		Estimations with cumulative outcomes after retirement age
****************************************************************************

local replace replace
foreach cohort in $cohorts{
	
	if inlist("`cohort'", "M50", "M54"){
		local retire = 60
	}
	else{
		local retire = 55
	}
	
	use if (poblacion_`cohort' == 1) using "$data\Estimation_sample_RIPS.dta", clear // Only use that cohort (faster)

	keep if age >= `retire'

	* Process raw data to create relevant variables
	quietly{
		
		rename (nro_serviciosHospitalizacion nro_serviciosurgencias 			///
		nro_serviciosprocedimientos nro_serviciosconsultas) 					///
		(nro_Hospitalizacion nro_urgencias nro_procedimientos nro_consultas)
		
		labvars cardiovascular chronic cons_psico consul estres hosp infarct 	///
		nro_Hospitalizacion nro_consultas nro_procedimientos nro_servicios 		///
		nro_urgencias pre_MWI proce service urg "Cardiovascular" 				///
		"Chronic disease" "Consultation with psychologist" 						///
		"Probability of consultation" "Stress" "Probability of hospitalization" ///
		"Infarct" "Number of hospitalizations" "Number of consultations" 		///
		"Number of procedures" "Number of services" "Number of ER visits" 		///
		"Multi-morbidity index" "Probability of procedures" 					///
		"Probability of health service" "Probability of ER visit"
		
		egen nro_servicios = rowtotal(nro_Hospitalizacion nro_urgencias 	///
		nro_procedimientos nro_consultas)

		keep $outcomes poblacion* age std_weeks // For efficiency
		
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
			
			dis as err "Regression for `outcome' with BW `bw' in cohort `cohort'"
			
			rdrobust `outcome' std_weeks if poblacion_`cohort' == 1 & 	///
			age == `age', vce(cluster std_weeks) h(-`bw' `bw') b(-`bw' `bw')
			
			local B: 	dis %010.`dec'fc e(tau_bc)
			local B: 	dis strtrim("`B'")

			if abs(`t') >= 1.645 {
				local B = "`B'*"
			}
			if abs(`t') >= 1.96 {
				local B = "`B'*"
			}	
			if abs(`t') >= 2.576 {
				local B = "`B'*"
			}
			
			rdplot `outcome' std_weeks if poblacion_`cohort' == 1 & 			///
			inrange(std_weeks,-`bw',`bw'), vce(cluster std_weeks) p(1) 			///
			kernel(triangular) h(`bw' `bw') binselect(esmv) ci(95) shade		///
			graph_options(title(`vallab', size(medium)) 						///
			subtitle(Cohort: `cohort'; Weeks around cutoff: `bw', size(small)) 	///
			xtitle(Distance to week of birth's cutoff) ytitle(`title') 			///
			legend(rows(1) position(bottom)) ylabel(, format(%010.`dec'fc)) 	///
			note("Rdrobust coefficient: `B'"))
			
			
			graph export "${graphs}\\`outcome'_`cohort'_`bw'.png", replace
			
			local replace append
		}
	}
}

log close
