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
use "${data}/Estimation_sample_PILA", clear

collapse (mean) fechantomode poblacion* std*, by(personabasicaid)

compress
save "${data}/Master_for_RIPS.dta", replace
	
	