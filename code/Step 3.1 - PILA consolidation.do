/*************************************************************************
 *************************************************************************			       	
	        PILA consolidation
			 
1) Created by: Pablo Uribe
			   Yale University
			   p.uribe@yale.edu
				
2) Date: April 2023

3) Objective: Get labor market data
           
4) Output:    - mensual_PILA.dta

*************************************************************************
*************************************************************************/	
clear all

****************************************************************************
* Globals
****************************************************************************

capture log close
log	using "${logs}\PILA mensual.smcl", replace


****************************************************************************
**#         1. Loop through PILA months
****************************************************************************

gen delete = 0
save "${data}\mensual_PILA", replace
global loop "01 02 03 04 05 06 07 08 09 10 11 12"
forval y = 2009/2020 {
	
	clear all
	gen delete = .
	tempfile temp_pila_`y'
	save `temp_pila_`y'', replace
	
	foreach i of global loop {

		di as err "********* `y'm`i' *********"
		cd "${pila_og}"
		use "`y'm`i'cBR", clear
		
		cap drop year month
		
		gen year = `y'
		gen month = `i'
		gen fecha_pila=ym(`y',`i')
		format fecha_pila %tm
		
		drop if mi(fechantomode) | mi(sexomode)
		
		gen day_birth = doy(fechantomode)

		* Mass accumulation of people born on January 1st. Drop them
		drop if day_birth == 1
				
		*New variables
		gen ibc_salud 			= ibc_sal
		gen dias_cot_salud 		= sal_dias_cot
		gen tipo_cotizante 		= tipo_cotiz
		
		gen pila_independientes = inlist(tipo_cotizante, 2, 3, 16, 41, 42, ///
                                  59, 57, 66)
		
		gen pila_posgrad_salud 	= (tipo_cotizante == 21)	
		gen pila_dependientes   = (pila_independientes != 1 &       ///
            pila_posgrad_salud! = 1)
				
		foreach var of varlist salario_bas ibc_pens ibc_sal ibc_rprof {
		    
			rename `var' `var'_orig
            
			bys personabasicaid id: egen 	`var' = max(`var'_orig) if  ///
                (pila_dependientes == 1)
                
			bys personabasicaid id: replace `var' = `var'_orig      if  ///
                (pila_independientes == 1)
			
		}
		
		drop salario_bas_orig ibc_pens_orig ibc_sal_orig ibc_rprof_orig day_birth
		
		*Minimum wage per year
		gen     mw = 461500  if year==2008
		replace mw = 496900  if year==2009
		replace mw = 515000  if year==2010
		replace mw = 535600  if year==2011
		replace mw = 566700  if year==2012
		replace mw = 589500  if year==2013
		replace mw = 616000  if year==2014
		replace mw = 644350  if year==2015
		replace mw = 689455  if year==2016
		replace mw = 737717  if year==2017
		replace mw = 781242  if year==2018
		replace mw = 828116  if year==2019
		replace mw = 877803  if year==2020
		replace mw = 908526  if year==2021
		replace mw = 1000000 if year==2022
		
		*Minimum wage t-1
		gen     mw_1 = 461500  if (year == 2009)
		replace mw_1 = 496900  if (year == 2010)
		replace mw_1 = 515000  if (year == 2011)
		replace mw_1 = 535600  if (year == 2012)
		replace mw_1 = 566700  if (year == 2013)
		replace mw_1 = 589500  if (year == 2014)
		replace mw_1 = 616000  if (year == 2015)
		replace mw_1 = 644350  if (year == 2016)
		replace mw_1 = 689455  if (year == 2017)
		replace mw_1 = 737717  if (year == 2018)
		replace mw_1 = 781242  if (year == 2019)
		replace mw_1 = 828116  if (year == 2020)
		replace mw_1 = 877803  if (year == 2021)
		replace mw_1 = 908526  if (year == 2022)
		replace mw_1 = 1000000 if (year == 2023)
		
		egen    rowmax 	= rowmax(ibc*)
		replace rowmax 	= mw if (rowmax >= mw_1 * 0.8 & rowmax < mw)		
		replace rowmax 	= rowmax / 0.4 if (pila_independientes == 1 &   ///
                rowmax > mw)
		
		replace salario_bas = mw if (rowmax >= mw_1 * 0.8 & rowmax < mw)
		
		egen    pila_salario = rowmax(rowmax salario_bas)
		replace pila_salario = .  if (pila_posgrad_salud == 1)
		lab var pila_salario "Salario nominal"
		drop 	rowmax
		
		gen     pila_salario_max = pila_salario
		
		*Get the CPI
		merge m:1 year month using "${ipc}\IPC mensual", keep(1 3) nogen
		
		*Generate real wages (base 2018m12)
		global vars pila_salario pila_salario_max arp_cot_obl ibc_rprof ibc_pens
		
		foreach var in $vars {
			
			gen     `var'_r = (`var' / IPC) * 100
			replace `var'_r = . if mi(`var')
			
		}

		gen tasa_riesgop = arp_cot_obl_r/ibc_rprof_r
		gen pension = (retiro == "P")
		
		replace afp_cod = strtrim(afp_cod)
		replace afp_cod = subinstr(afp_cod, " ", "-", .)
		replace afp_cod = "25-11" if afp_cod == "25-11-"
		
		rename  dias_cot_salud pila_dias_cot
		
		* Remove duplicates of contributions with same company
		gduplicates drop personabasicaid id if pila_dependientes == 1, force
			
		* Since people may have more than one contribution each month, sum the 
        * wages of each contribution and keep the max of worked days.
		foreach var of varlist pila_salario_r {
			
			bys personabasicaid: ereplace 	`var'                = total(`var')
            
			bys personabasicaid: egen       `var'_dependientes   = total(`var') ///
                if (pila_dependientes == 1)
                
			bys personabasicaid: egen       `var'_independientes = total(`var') ///
                if (pila_independientes == 1)
			
		}
		
		foreach var of varlist sal_dias_cot pila_dependientes       ///
            pila_independientes pila_posgrad_salud tasa_riesgop pension {
			
		  bys personabasicaid: ereplace `var' = max(`var')  
		  
		}
		
		replace sal_dias_cot    = 30 if sal_dias_cot  > 30 & !mi(sal_dias_cot)
		replace pens_dias_cot 	= 30 if pens_dias_cot > 30 & !mi(pens_dias_cot)
		
		gsort personabasicaid -afp_cod
		
		gduplicates drop personabasicaid, force
		
		tostring ciudad_cod depto_cod, replace
		
		replace ciudad_cod = "00" + ciudad_cod if length(ciudad_cod) == 1 & ///
                ciudad_cod != "."
                
		replace ciudad_cod = "0"  + ciudad_cod if length(ciudad_cod) == 2 & ///
                ciudad_cod != "."
		
		replace depto_cod  = "0"  + depto_cod  if length(depto_cod) == 1  & ///
                depto_cod != "."
		
		gen pila_cod_mun = depto_cod + ciudad_cod
		
		*Keep relevant variables
		keep personabasicaid fecha_pila year month sexomode fechantomode 	///
	    pila_independientes pila_dependientes id sal_dias_cot tasa_riesgop 	///
		pension pens_dias_cot afp_cod *_r
		
		*Remove any duplicates
		gduplicates drop personabasicaid, force
		
		compress
		
		merge 1:1 personabasicaid using "${data}\Master_sample.dta", keep(2 3) ///
		keepusing(personabasicaid sexomode fechantomode)
		
		replace year  		= `y' 			if _merge == 2
		replace month 		= `i' 			if _merge == 2
		replace fecha_pila 	= ym(`y',`i') 	if _merge == 2
		format fecha_pila %tm
		
		append using `temp_pila_`y''
		tempfile temp_pila_`y'
		save `temp_pila_`y'', replace		
	}
	
	append using "${data}\mensual_PILA"
	save "${data}\mensual_PILA", replace
}

*drop if inrange(month,9,12) & year == 2022

drop delete

compress

save "${data}\mensual_PILA", replace

log close
