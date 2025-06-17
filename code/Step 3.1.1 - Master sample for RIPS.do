/*************************************************************************
 *************************************************************************			       	
	        Master sample for RIPS
			 
1) Created by: Pablo Uribe
			   Yale University
			   p.uribe@yale.edu
				
2) Date: April 2023

3) Objective: Consolidate master sample using only those in Colpensiones
           
4) Output:    - Master_for_RIPS.dta

*************************************************************************
*************************************************************************/	
clear all

****************************************************************************
**#         1. Get PILA sample and restrict
****************************************************************************
use "${data}\mensual_PILA", clear

* Process raw data to create relevant variables
    
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

* Dummy for whether they are affiliated to the public fund
gen colpensiones = (inlist(afp_cod, "25-14", "25-11" ,"25-8", "ISSFSP"))

keep poblacion* year month std_weeks std_days fecha_pila personabasicaid colpensiones fechantomode sexomode // For efficiency

bys personabasicaid: egen ever_colpensiones = max(colpensiones)

keep if ever_colpensiones == 1

collapse (mean) fechantomode poblacion* std*, by(personabasicaid)

compress
save "${data}/Master_for_RIPS.dta", replace
	
	