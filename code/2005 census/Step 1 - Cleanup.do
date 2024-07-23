/*************************************************************************
 *************************************************************************			       	
	        Process census data
			 
1) Created by: Pablo Uribe
			   Yale University
			   p.uribe@yale.edu
				
2) Date: June 2023

3) Objective: Process 2005 census data from IPUMS
           
4) Output:    - processed_census.dta

*************************************************************************
*************************************************************************/	
clear all

****************************************************************************
* Globals
****************************************************************************

global data "C:\Users\Pablo Uribe\Desktop\BanRep\Pensions\Data"

global redefine wall garbage elec sewer runwat natgas phone toilet water    ///
       kitchex watsrc refrig washer stereo watheat shower blender oven      ///
       aircond fan tvc compute microw sex ill mdcar mdorg mdneu mdtra       ///
       mdcon mdjoi mddia mdbur mdaid mdche mdint lit

****************************************************************************
* Import data, get DOB and create dummies
****************************************************************************

use "${data}\ipumsi_00002.dta", clear

drop pernum *_pernum *_strata

rename co2005a_* * // Remove prefix

*** Arbitrary decision: Impute day of birth = 15 to all observations (day of birth is not included in the data)
gen fecha = "15" + "/" + string(bmon) + "/" + string(byr)

*** Arbitrary decision: Impute January to observations without a month of birth (doesn't affect the poblacion conditions since they all start in January of a given year). This happens for 5.4% of the sample defined in line 22
replace fecha = "15" + "/" + "1" + "/" + string(byr) if bmon == 99

gen fechanto = date(fecha, "DMY")

format fechanto %td

gen poblacion_M50  = 1 if sex == 1 & inrange(fechanto, -4383, -2557)
*gen poblacion_M54 = 1 if sex == 1 & inrange(fechanto, -2922, -1096)
gen poblacion_F55  = 1 if sex == 2 & inrange(fechanto, -2556, -731)
*gen poblacion_F59 = 1 if sex == 2 & inrange(fechanto, -1095, 730)

keep if !mi(poblacion_M50) | !mi(poblacion_F55) // Keep people in our age ranges


** Redifining variables to create dummies
foreach var of global redefine {
    
	replace `var' = 0 if inrange(`var', 2, 9)
    
}

replace empstat = 0 if inrange(empstat, 2, 98)
replace pension = 0 if inlist(pension, 2, 8)
replace pension = 1 if pension == 3

gen more4peop_dwelling = (pernd > 4)
gen cement_floor       = (floor == 3)
gen atleast1bathrm     = (inrange(roomsba, 1, 10))
gen owns_dwelling      = (tenure == 2)
gen fuel_cook          = (inrange(fuelck, 1, 3))
gen has_bike           = (inrange(bike, 1, 9))
gen has_moto           = (inrange(motorcy, 1, 3))
gen has_car            = (inrange(auto, 1, 4))
gen enough_income      = (inlist(incbas, 1, 2))
gen atleast_highschool = (inrange(edlev, 4, 12))

* Label variables
labvars more4peop_dwelling cement_floor wall garbage elect sewer runwat   ///
natgas phone toilet water atleast1bathrm kitchex owns_dwelling watsrc     ///
fuel_cook refrig washer stereo watheat shower blender oven aircond fan    ///
tvc compute microw has_bike has_moto has_car enough_income sex ill mdcar  ///
mdorg mdneu mdtra mdcon mdjoi mddia mdbur mdaid mdche mdint lit           ///
atleast_highschool pension empstat "More than 4 persons in dwelling"      ///
"Cement floor" "Cement, brick, stone, or polished wood wall"              ///
"Garbage collected by trash service" "Electrical energy" "Sewage drains"  ///
"Running water" "Natural gas" "Telephone" "Toilet connected to sewage"    ///
"Water service inside" "At least 1 bathroom" "Exclusive area for cooking" ///
"Owns dwelling" "Water from aqueduct"                                     ///
"Electrical, natural gas, or gas tank for cooking" "Refrigerator"         ///
"Washing machine" "Sound equipment" "Water heater" "Electric shower"      ///
"Blender" "Oven" "Air conditioner" "Fan" "Color TV" "Computer"            ///
"Microwave" "Has bicycle" "Has motorcycle" "Has car"                      ///
"Income enough for basic expenses" "Male" "Was ill in past year"          ///
"Cardiac surg. in past year" "Organ transplant in past year"              ///
"Neurosurgery in past year" "Major trauma in past five years"             ///
"Congenital illness" "Joint replacement"                                  ///
"Dialysis for chronic insufficiency" "Serious burns" "HIV/AIDS"           ///
"Chemotherapy" "Intensive care" "Literate"                                ///
"Completed at least high school" "Affiliated or retired from pension fund" ///
"Works"

compress

save "${data}\processed_census.dta", replace
