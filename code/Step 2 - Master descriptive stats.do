****************************************************************************
* This file plots the histograms of the master dataset
*
*
* AUTHOR:	Pablo Uribe
* LOCATION:	Medellin, Colombia
* DATE:		April, 2023
*
****************************************************************************
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


use "$data\master_sample.dta", clear


* Histograms using roughly a bin per week (5 years * 52 weeks = 260)
set scheme white_tableau
	
qui rddensity std_weeks if poblacion_M50 == 1
local pvalue: dis %04.3f e(pv_q)

twoway (hist fechantomode if poblacion_M50 == 1, xla(#15, angle(90) format("%td")) xtitle(Date of birth) title(Men born between 48-52) note("Manipulation test p-value: `pvalue'") bin(260) freq) (pci 0 -3441 1500 -3441, color(red)), legend(off)

graph export "$graphs\hist_M50.png", replace

qui rddensity std_weeks if poblacion_M54 == 1
local pvalue: dis %04.3f e(pv_q)

twoway (hist fechantomode if poblacion_M54 == 1, xla(#15, angle(90) format("%td")) xtitle(Date of birth) title(Men born between 52-56) note("Manipulation test p-value: `pvalue'") bin(260) freq) (pci 0 -1827 3000 -1827, color(red)), legend(off)

graph export "$graphs\hist_M54.png", replace


qui rddensity std_weeks if poblacion_F55 == 1
local pvalue: dis %04.3f e(pv_q)

twoway (hist fechantomode if poblacion_F55 == 1, xla(#15, angle(90) format("%td")) xtitle(Date of birth) title(Women born between 53-57) note("Manipulation test p-value: `pvalue'") bin(260) freq) (pci 0 -1615 1500 -1615, color(red)), legend(off)

graph export "$graphs\hist_F55.png", replace


qui rddensity std_weeks if poblacion_F59 == 1
local pvalue: dis %04.3f e(pv_q)

twoway (hist fechantomode if poblacion_F59 == 1, xla(#15, angle(90) format("%td")) xtitle(Date of birth) title(Women born between 57-61) note("Manipulation test p-value: `pvalue'") bin(260) freq) (pci 0 -1 2500 -1, color(red)), legend(off)

graph export "$graphs\hist_F59.png", replace



