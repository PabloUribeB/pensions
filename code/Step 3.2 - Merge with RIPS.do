/*************************************************************************
 *************************************************************************			       	
	        RIPS consolidation
			 
1) Created by: Pablo Uribe
			   Yale University
			   p.uribe@yale.edu
				
2) Date: April 2023

3) Objective: Get health data
           
4) Output:    - Merge_individual_RIPS.dta

*************************************************************************
*************************************************************************/	
clear all


****************************************************************************
**#         1. Loop through RIPS years
****************************************************************************

global b "consultas procedimientos urgencias Hospitalizacion"

* Population of interest in any RIPS dataset
forvalues year = 2009/2021 {
    
	clear
	gen aux = ""
	save "${data}\RIPS\sample_`year'_RIPS", replace
	
	foreach base of global b {
		
		dis in red "`base'`year'"
		
		if "`base'" == "consultas" | "`base'" == "procedimientos" {
		
			if "`base'"=="consultas" {
				local date = "fecha_consul"
				local diag = "cod_diag_prin"
				local extra_diag = "cod_diag_r1 cod_diag_r2 cod_diag_r3"
				local causa = "causa_externa"
				local consul = "cod_consul"
				local lrename rename (cod_diag_r1 cod_diag_r2 cod_diag_r3) (diag_r1 diag_r2 diag_r3)
			}
					
			if "`base'" == "procedimientos" {
				local date = "fecha"
				local diag = "diag_prin"
				local extra_diag = "diag_r1"
				local causa = ""
				local consul = ""
				local lrename = ""
			}
			
			
			if `year' < 2019 {
			
				use personabasicaid `diag' `date' `extra_diag' `causa'  ///
                    `consul' using "${RIPS}\\`base'`year'", clear
				
				gen date = date(substr(`date',1,10),"YMD")
				format date %td
				
				`lrename'
								
				compress
			}
			
			else {
				if "`base'"=="consultas" {
					local vari_id = "Id"
					local max_i = 3
				}
				
				else {
					local vari_id = "ID"
					
					if `year' == 2020 {
						local max_i = 5
					}
					else {
						local max_i = 4
					}
				}
				
				clear
				gen x = ""
				save "${data}/`base'_`year'", replace
				
				forvalues i = 1/`max_i' {
                    
					use personabasicaid `diag' `date' `extra_diag'      ///
                        `causa' `consul' using                          ///
                        "${RIPS2}\\`base'`vari_id'`year'_`i'", clear
										
					compress
					
					append using "${data}/`base'_`year'"
					save "${data}/`base'_`year'", replace
				}
				
				use "${data}/`base'_`year'", clear
				
				gen date = date(substr(`date',1,10) ,"YMD")
				format date %td
				
				`lrename'
				
				erase "${data}/`base'_`year'.dta"
			}
		}
		
		else {
            
			if "`base'" == "urgencias" {
                
				use personabasicaid diag_prin diag_r1 diag_r2 diag_r3   ///
                    fecha_ingreso dead causa_externa using              ///
                    "${urgencias}\Master_urgencias_2009_2022", clear
				
				gen date = date(substr(fecha_ingreso,1,10),"YMD")
				format date %td
				
			}
			
			else {
                
				use personabasicaid diag_prin_ingre diag_egre1 diag_egre2 ///
                    diag_egre3 date dead diag_muerte causa_externa using  ///
                    "${urgencias}\Master_hospitalizaciones_2009_2022", clear
				
				rename (diag_egre1 diag_egre2 diag_egre3)       ///
                       (diag_r1 diag_r2 diag_r3)
			}
			
			compress
			
			keep if year(date) == `year'
		}
		
		gen service = "`base'"
		
		drop if mi(personabasicaid)
		
		cap drop aux
	
		destring personabasicaid, force replace
		
		* Aqui haces el merge con tu base master de personabasicaid
		merge m:1 personabasicaid using "${data}\Master_sample.dta",    ///
              keep(3) nogen
		
		cap noi destring causa_externa, replace
		
		append using "${data}\RIPS\sample_`year'_RIPS"
	
		compress
		save "${data}\RIPS\sample_`year'_RIPS", replace
	}
}


***
* We just got 2022 data but it's not processed yet, so we have to import the .txt files.
* Hopefully, it's going to be inside the loop soon.

clear
gen aux = ""
save "${data}\RIPS\sample_2022_RIPS", replace

**#
forvalues i = 1/8 {
	* Emergencies
	if `i' == 1 {
	    
		local service = "urgencias"
		
		use personabasicaid diag_prin diag_r1 diag_r2 diag_r3           ///
            fecha_ingreso dead causa_externa using                      ///
            "${urgencias}\Master_urgencias_2009_2022", clear
	
		gen date = date(substr(fecha_ingreso,1,10),"YMD")
		format date %td
				
		keep if year(date) == 2022
	}
	
	* Hospitalizations
	if `i' == 2 {
	    
		local service = "Hospitalizacion"
		
		use personabasicaid diag_prin_ingre diag_egre1 diag_egre2       ///
            diag_egre3 date dead diag_muerte causa_externa using        ///
            "${urgencias}\Master_hospitalizaciones_2009_2022", clear
		
		rename (diag_egre1 diag_egre2 diag_egre3) (diag_r1 diag_r2 diag_r3)
				
		keep if year(date) == 2022
	}
	
	* Consultations
	if `i' == 3 | `i' == 4 {
	    
		local service = "consultas"
		
		if `i' == 3 {
			import delimited "${RIPS2}\BANREP_consultas2022_01_04.txt", clear
		}
		
		else {
			import delimited "${RIPS2}\BANREP_consultas2022_05_09.txt", clear
		}
				
		keep personabasicaid cod_diag_prin cod_diag_r1 cod_diag_r2      ///
             cod_diag_r3 fecha_consul causa_externa cod_consul
					
		rename (cod_diag_r1 cod_diag_r2 cod_diag_r3) (diag_r1 diag_r2 diag_r3)

		gen date = date(substr(fecha,1,10) ,"YMD")
		format date %td
	}
	
	* Procedures
	if `i' > 4 {
	    
		local service = "procedimientos"
		
		if `i' == 5 {
			import delimited "${RIPS2}\BANREP_proc2022_01_02.txt", clear
		}
		
		if `i' == 6 {
			import delimited "${RIPS2}\BANREP_proc2022_03_04.txt", clear
		}
		
		if `i' == 7 {
			import delimited "${RIPS2}\BANREP_proc2022_05_06.txt", clear
		}
		
		if `i' == 8 {
			import delimited "${RIPS2}\BANREP_proc2022_07_09.txt", clear
		}
				
		keep personabasicaid diag_prin diag_r1 fecha
		
		gen date = date(substr(fecha,1,10) ,"YMD")
		format date %td
	}
	
	destring personabasicaid, force replace
	
	cap drop aux
	
	merge m:1 personabasicaid using "${data}\Master_sample.dta", keep(3) nogen
		
	gen service = "`service'"
	
	drop if mi(personabasicaid)
			
	append using "${data}\RIPS\sample_2022_RIPS"
	
	compress
	save "${data}\RIPS\sample_2022_RIPS", replace
}



********************************************************************************
**#                          1. Merge with RIPS            
********************************************************************************

clear all
gen aux = .
save "${data}\Merge_individual_RIPS.dta", replace
 
forval y = 2009/2022 {
	
	dis as err "RIPS `y'"
	use "${data}\RIPS\sample_`y'_RIPS.dta", clear
	cap destring yearmode, replace
	
	* Unify diagnosis code
	replace diag_prin = diag_prin_ingre if mi(diag_prin) & !mi(diag_prin_ingre)
	
	replace diag_prin = cod_diag_prin if mi(diag_prin) & !mi(cod_diag_prin)
	
	append using "${data}\Merge_individual_RIPS.dta", force
	
	cap drop aux
	
	compress

	save "${data}\Merge_individual_RIPS.dta", replace
}

** Erase all temporary files
forval y = 2009/2022 {
	erase "${data}\RIPS\sample_`y'_RIPS.dta"
}
