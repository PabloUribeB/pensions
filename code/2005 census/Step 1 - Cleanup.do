global data "C:\Users\Pablo Uribe\Desktop\BanRep\Pensions\Data"

use "$data\ipumsi_00002.dta" , clear

drop pernum *_pernum *_strata

rename co2005a_* *

*** Arbitrary decision: Impute day of birth = 15 to all observations (day of birth is not included in the data)
gen fecha = "15" + "/" + string(bmon) + "/" + string(byr)

*** Arbitrary decision: Impute January to observations without a month of birth (doesn't affect the poblacion conditions since they all start in January of a given year). This happens for 5.4% of the sample defined in line 22
replace fecha = "15" + "/" + "1" + "/" + string(byr) if bmon == 99

gen fechanto = date(fecha,"DMY")

format fechanto %td

gen poblacion_M50 = 1 if sex == 1 & inrange(fechanto,-4383,-2557)
*gen poblacion_M54 = 1 if sex == 1 & inrange(fechanto,-2922,-1096)
gen poblacion_F55 = 1 if sex == 2 & inrange(fechanto,-2556,-731)
*gen poblacion_F59 = 1 if sex == 2 & inrange(fechanto,-1095,730)

keep if !mi(poblacion_M50) | !mi(poblacion_F55)

** Redifining variables to create dummies
global redefine wall garbage elec sewer runwat natgas phone toilet water kitchex watsrc refrig washer stereo watheat shower blender oven aircond fan tvc compute microw sex ill mdcar mdorg mdneu mdtra mdcon mdjoi mddia mdbur mdaid mdche mdint lit

foreach var of varlist $redefine{
	replace `var' = 0 if inrange(`var',2,9)
}

replace empstat = 0 if inrange(empstat,2,98)
replace pension = 0 if inlist(pension,2,8)
replace pension = 1 if pension == 3

gen more4peop_dwelling = (pernd > 4)
gen cement_floor = (floor == 3)
gen atleast1bathrm = (inrange(roomsba,1,10))
gen owns_dwelling = (tenure == 2)
gen fuel_cook = (inrange(fuelck,1,3))
gen has_bike = (inrange(bike,1,9))
gen has_moto = (inrange(motorcy,1,3))
gen has_car = (inrange(auto,1,4))
gen enough_income = (inlist(incbas,1,2))
gen atleast_highschool = (inrange(edlev,4,12))


label var more4peop_dwelling 	"More than 4 persons in dwelling"
label var cement_floor 			"Cement floor"
label var wall 					"Cement, brick, stone, or polished wood wall"
label var garbage 				"Garbage collected by trash service"
label var elect 				"Electrical energy"
label var sewer 				"Sewage drains"
label var runwat 				"Running water"
label var natgas 				"Natural gas"
label var phone 				"Telephone"
label var toilet 				"Toilet connected to sewage"
label var water 				"Water service inside"
label var atleast1bathrm 		"At least 1 bathroom"
label var kitchex 				"Exclusive area for cooking"
label var owns_dwelling 		"Owns dwelling"
label var watsrc 				"Water from aqueduct"
label var fuel_cook 			"Electrical, natural gas, or gas tank for cooking"
label var refrig 				"Refrigerator"
label var washer 				"Washing machine"
label var stereo 				"Sound equipment"
label var watheat 				"Water heater"
label var shower 				"Electric shower"
label var blender 				"Blender"
label var oven 					"Oven"
label var aircond 				"Air conditioner"
label var fan 					"Fan"
label var tvc 					"Color TV"
label var compute 				"Computer"
label var microw 				"Microwave"
label var has_bike 				"Has bicycle"
label var has_moto 				"Has motorcycle"
label var has_car 				"Has car"
label var enough_income 		"Income enough for basic expenses"
label var sex 					"Male"
label var ill 					"Was ill in past year"
label var mdcar 				"Cardiac surg. in past year"
label var mdorg 				"Organ transplant in past year"
label var mdneu 				"Neurosurgery in past year"
label var mdtra 				"Major trauma in past five years"
label var mdcon			 		"Congenital illness"
label var mdjoi 				"Joint replacement"
label var mddia 				"Dialysis for chronic insufficiency"
label var mdbur 				"Serious burns"
label var mdaid 				"HIV/AIDS"
label var mdche 				"Chemotherapy"
label var mdint 				"Intensive care"
label var lit 					"Literate"
label var atleast_highschool 	"Completed at least high school"
label var pension 				"Affiliated or retired from pension fund"
label var empstat 				"Works"

compress

save "$data\processed_census", replace
