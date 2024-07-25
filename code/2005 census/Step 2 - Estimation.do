/*************************************************************************
 *************************************************************************			       	
	        Balance tests with census data
			 
1) Created by: Pablo Uribe
			   Yale University
			   p.uribe@yale.edu
				
2) Date: June 2023

3) Objective: Estimate balance regressions
           
4) Output:    - balance.png files

*************************************************************************
*************************************************************************/	
clear all

****************************************************************************
* Globals
****************************************************************************

global covars sex ill mdcar mdorg mdneu mdtra mdcon mdjoi mddia mdbur mdaid ///
mdche mdint lit empstat pension atleast_highschool wall garbage elec sewer  ///
runwat natgas phone toilet water kitchex watsrc refrig washer stereo        ///
watheat shower blender oven aircond fan tvc compute microw                  ///
more4peop_dwelling cement_floor atleast1bathrm owns_dwelling fuel_cook      ///
has_moto has_bike enough_income has_car

global rownames " "Male" "Was ill in past year" "Cardiac surgery in past year" "Organ transplant in past year" "Neurosurgery in past year" "Major trauma in past five years" "Congenital illness" "Joint replacement" "Dialysis for chronic insuff" "Serious burns" "HIV/AIDS" "Chemotherapy" "Intensive care" "Literate" "Works" "Affil or ret from pension fund" "Completed at least high school" "Cement, brick, stone wall" "Garbage by trash service" "Electrical energy" "Sewage drains" "Running water" "Natural gas" "Telephone" "Toilet connected to sewage" "Water service inside" "Exclusive area for cooking" "Water from aqueduct" "Refrigerator" "Washing machine" "Sound equipment" "Water heater" "Electric shower" "Blender" "Oven" "Air conditioner" "Fan" "Color TV" "Computer" "Microwave" "More than 4 persons in dwelling" "Cement floor" "At least 1 bathroom" "Owns dwelling" "Electrical, natural gas cooking" "Has motorcycle" "Has bicycle" "Has car" "Income enough for basic expenses" "

local size: list sizeof global(rownames)

matrix balance             = J(`size', 3, .)
matrix balanceRD           = J(`size', 3, .)
matrix balanceRD_final     = J(15, 3, .)
matrix balanceRD_final_M50 = J(15, 3, .)
matrix balanceRD_final_F55 = J(15, 3, .)

foreach name in balance balanceRD balanceRD_final balanceRD_final_M50 ///
balanceRD_final_F55 {
            
    matrix rownames `name' = $rownames
            
}

* String of plot options
local plot_options = "bylabels(, wrap(15)) "                                  ///
+ "byopts(compact rows(1) legend(off)) scheme(s1color) "                      ///
+ "graphregion(fcolor(white))  plotregion(fcolor(white))  msize(medium) "     ///
+ "xline(0, lwidth(thin)) ciopts(recast(rcap) lcolor(black)) "                ///
+ "ylabel(, labsize(*0.5)) mfcolor(white) "                                   ///
+ "subtitle(, size(small) color(black) bcolor(white) justification(center)) " ///
+ "grid(between glpattern(dash) glwidth(vvthin) glcolor(black))  msymbol(o) " ///
+ "mlcolor(black)  mlabposition(0) coeflabels(,wrap(45))"

****************************************************************************
**#         1. Import data, create sample variables
****************************************************************************

use "${ext_data}\processed_census.dta" , clear

gen     corte = -3441 if poblacion_M50 == 1
*replace corte = -1827 if poblacion_M54 == 1
replace corte = -1615 if poblacion_F55 == 1
*replace corte = -1 if poblacion_F59 == 1

gen fechaweek  = wofd(fechanto)
format %td corte
gen corte_week = wofd(corte)

gen std_weeks = fechaweek - corte_week

gen     bw = 0 if inrange(std_weeks, -20, 0)
replace bw = 1 if inrange(std_weeks, 0, 20)

foreach var of varlist poblacion* {
    
    replace `var' = 0 if mi(`var')
    
}

gen     cohort = 1 if poblacion_M50 == 1
*replace cohort = 2 if poblacion_M54 == 1
replace cohort = 3 if poblacion_F55 == 1
*replace cohort = 4 if poblacion_F59 == 1

svyset [pw=wtperc] // Set data as survey

****************************************************************************
**#       2. Balance regressions
****************************************************************************

local row=1
foreach outcome in $covars{
	
	svy: reg `outcome' bw i.cohort
	
	mat balance[`row',1] = _b[bw]
	mat balance[`row',2] = _b[bw]  - _se[bw]*1.96
	mat balance[`row',3] = _b[bw]  + _se[bw]*1.96
	
	local row = `row' + 1
}

matsave balance, replace saving path("${tables}")

svy: reg bw $covars i.cohort

test $covars

local pvalue: dis %7.3f r(p)


coefplot matrix(balance[,1]), ci((balance[,2] balance[,3]))             ///
`plot_options'                                                          ///
groups("Was ill in past year"-"Intensive care" = "{bf:Health}"          ///
"Literate"-"Completed at least high school" = "{bf:Personal}"           ///
"Cement, brick, stone wall"-"Income enough for basic expenses" = "{bf:Household}", labs(*0.6)) ///
note(Joint test p-value: `pvalue')
		 
graph export "${graphs}\balance.png", replace

		 
** Using RD specification
gen above = (std_weeks >= 0)
gen std_weeks2 = std_weeks ^ 2

local row=1
foreach outcome in $covars{
	
	rdbwselect `outcome' std_weeks, covs(poblacion_F55 poblacion_F59 poblacion_M50)
	local h = e(h_mserd)
	
	svy: reg `outcome' above##c.std_weeks i.cohort if abs(std_weeks) <= `h'
	
	mat balanceRD[`row',1] = _b[1.above]
	mat balanceRD[`row',2] = _b[1.above]  - _se[1.above]*1.96
	mat balanceRD[`row',3] = _b[1.above]  + _se[1.above]*1.96
	
	local row = `row' + 1
}

matsave balanceRD, replace saving path("${tables}")

coefplot matrix(balanceRD[,1]), ci((balanceRD[,2] balanceRD[,3]))       ///
`plot_options'                                                          ///
groups("Was ill in past year"-"Intensive care" = "{bf:Health}"          ///
"Literate"-"Completed at least high school" = "{bf:Personal}"           ///
"Cement, brick, stone wall"-"Income enough for basic expenses" = "{bf:Household}", labs(*0.6))
		 
graph export "${graphs}\balance_RD.png", replace




****************************************************************************
**#       3. Final covariates used (final plots)
****************************************************************************
gen above = (std_weeks >= 0)
gen std_weeks2 = std_weeks^2

global covars ill mdcar mdorg mdneu mdtra mdcon mdjoi mddia mdbur mdaid ///
mdche mdint empstat pension atleast_highschool

global rownames " "Was ill in past year" "Cardiac surgery in past year" "Organ transplant in past year" "Neurosurgery in past year" "Major trauma in past five years" "Congenital illness" "Joint replacement" "Dialysis for chronic insuff" "Serious burns" "HIV/AIDS" "Chemotherapy" "Intensive care" "Works" "Affil or ret from pension fund" "Completed at least high school" "

keep std_weeks poblacion_F55 poblacion_M50 above $covars wtperc cohort

compress


local row=1
foreach outcome in $covars{
	
	rdbwselect `outcome' std_weeks, covs(poblacion_F55 poblacion_M50)
	local h = e(h_mserd)
	
	svy: reg `outcome' above##c.std_weeks i.cohort if abs(std_weeks) <= `h'
	
	mat balanceRD_final[`row',1] = _b[1.above]
	mat balanceRD_final[`row',2] = _b[1.above]  - _se[1.above]*1.96
	mat balanceRD_final[`row',3] = _b[1.above]  + _se[1.above]*1.96
	
	local row = `row' + 1
}

matsave balanceRD_final, replace saving path("${tables}")

coefplot matrix(balanceRD_final[,1]),                                       ///
ci((balanceRD_final[,2] balanceRD_final[,3])) `plot_options'                ///
groups("Was ill in past year"-"Intensive care" = "{bf:Health}"              ///
"Works"-"Completed at least high school" = "{bf:Personal}", labs(*0.6))
		 
graph export "${graphs}\balanceRD_final.png", replace


** Cohort M50

local row=1
foreach outcome in $covars{
	
	rdbwselect `outcome' std_weeks if poblacion_M50 == 1
	local h = e(h_mserd)
	
	svy: reg `outcome' above##c.std_weeks if abs(std_weeks) <= `h' & poblacion_M50 == 1
	
	mat balanceRD_final_M50[`row',1] = _b[1.above]
	mat balanceRD_final_M50[`row',2] = _b[1.above]  - _se[1.above]*1.96
	mat balanceRD_final_M50[`row',3] = _b[1.above]  + _se[1.above]*1.96
	
	local row = `row' + 1
}

matsave balanceRD_final_M50, replace saving path("${tables}")

coefplot matrix(balanceRD_final_M50[,1]),                               ///
ci((balanceRD_final_M50[,2] balanceRD_final_M50[,3])) `plot_options'    ///
groups("Was ill in past year"-"Intensive care" = "{bf:Health}"          ///
"Works"-"Completed at least high school" = "{bf:Personal}", labs(*0.6))
		 
graph export "${graphs}\balanceRD_final_M50.png", replace



** Cohort F55

local row=1
foreach outcome in $covars{
	
	rdbwselect `outcome' std_weeks if poblacion_F55 == 1
	local h = e(h_mserd)
	
	svy: reg `outcome' above##c.std_weeks if abs(std_weeks) <= `h' & poblacion_F55 == 1
	
	mat balanceRD_final_F55[`row',1] = _b[1.above]
	mat balanceRD_final_F55[`row',2] = _b[1.above]  - _se[1.above]*1.96
	mat balanceRD_final_F55[`row',3] = _b[1.above]  + _se[1.above]*1.96
	
	local row = `row' + 1
}

matsave balanceRD_final_F55, replace saving path("${tables}")

coefplot matrix(balanceRD_final_F55[,1]),                               ///
ci((balanceRD_final_F55[,2] balanceRD_final_F55[,3])) `plot_options'    ///
groups("Was ill in past year"-"Intensive care" = "{bf:Health}"          ///
"Works"-"Completed at least high school" = "{bf:Personal}", labs(*0.6))
		 
graph export "${graphs}\balanceRD_final_F55.png", replace


