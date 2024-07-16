if "`c(hostname)'" == "SM201439"{
	global data "C:\Proyectos\Banrep research\Pensions\Data"
	global tables "C:\Proyectos\Banrep research\Pensions\Tables"
	global graphs "C:\Proyectos\Banrep research\Pensions\Graphs"
	global data_master "C:\Proyectos\PILA master"
}

else {
	global data "\\sm093119\Proyectos\Banrep research\Pensions\Data"
	global tables "\\sm093119\Proyectos\Banrep research\Pensions\Tables"
	global graphs "\\sm093119\Proyectos\Banrep research\Pensions\Graphs"
	global data_master "\\sm093119\Proyectos\PILA master"
}

use "$data_master\PILA_personabasicaid_fechanto_genero.dta", clear

* Men born between 1948 y 1952 (-4383 -2557) Población 1 Corte en -3441
* Men born between 1952 y 1956 (-2922 -1096) Población 2 Corte en -1827

* Women born between 1953 y 1957 (-2556 -731) Población 3 Corte en -1615
* Women born between 1957 y 1961 (-1095 730) Población 4 Corte en -1

gen poblacion_M50 = 1 if sexomode == 1 & inrange(fechantomode,-4383,-2557)
gen poblacion_M54 = 1 if sexomode == 1 & inrange(fechantomode,-2922,-1096)
gen poblacion_F55 = 1 if sexomode == 0 & inrange(fechantomode,-2556,-731)
gen poblacion_F59 = 1 if sexomode == 0 & inrange(fechantomode,-1095,730)

keep if !mi(poblacion_M50) | !mi(poblacion_F55)

destring yearmode, replace

gen day_birth = doy(fechantomode)

* Mass accumulation of people born on January 1st. Drop them
drop if day_birth == 1

* Starts at 0 on Sunday
gen weekday = dow(fechantomode)
gen month = month(fechantomode)
gen week = week(fechantomode)

/* Days from cutoff point for each group
gen std_days = datediff(-3441,fechantomode,"d") if poblacion == "M50"
replace std_days = datediff(-2101,fechantomode,"d") if poblacion == "M54"
replace std_days = datediff(-1615,fechantomode,"d") if poblacion == "F55"
replace std_days = datediff(-275,fechantomode,"d") if poblacion == "F59"
*/

gen corte = -3441 if poblacion_M50 == 1
replace corte = -1827 if poblacion_M54 == 1
replace corte = -1615 if poblacion_F55 == 1
replace corte = -1 if poblacion_F59 == 1

gen fechaweek = wofd(fechantomode)
format %td corte
gen corte_week = wofd(corte)

gen std_weeks = fechaweek - corte_week

compress
save "$data\Master_sample.dta", replace
