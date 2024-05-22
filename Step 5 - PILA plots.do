
global main "C:\Users\Pablo Uribe\Desktop\BanRep\Pensions"
global figures "${main}\Graphs"
global tables "${main}\Tables"

set graphics off

use "${tables}\PILA_results.dta", clear

gen date = ym(year, month)
format date %tm

encode outcome, gen(en_outcome)
label def labout 1 "Contributes to a pension fund" 2 "Contributes to Colpensiones" 3 "Real monthly wage (missings)" 4 "Real monthly wage (zeros)"
label val en_outcome labout

levelsof outcome, local(outcomes)
local outcome = 1
foreach variable in `outcomes'{
	
	if inlist("`variable'", "pila_salario_r", "pila_salario_r_0"){
		local dec = 0
	}
	else{
		local dec = 3
	}
	
	local vallab : label (en_outcome) `outcome'
	
	foreach cohort in M50 F55{
		
		tw (rspike ci_lower ci_upper date, lcolor(ebblue) lp(solid)) 		///
		(scatter coef date, mcolor(ebblue)) 								///
		if (cohort == "`cohort'" & outcome == "`variable'"), 				///
		legend(position(bottom) rows(1) order(1 "95% confidence interval" 	///
		2 "Point estimate")) xline(`=ym(2010,7)', lcolor(red)) 				///
		yline(0, lp(solid)) ytitle(Point estimate) 							///
		xlabel(`=ym(2009,1)'(2)`=ym(2011,12)', angle(45) labs(vsmall)) 		///
		xtitle(Date) ylabel(#10, format(%010.`dec'fc) labs(vsmall)) 		///
		title(`vallab', size(medium)) subtitle(Cohort: `cohort', size(medsmall))
		
		graph export "${figures}\\`variable'_`cohort'.png", replace
		
	}
	
	foreach cohort in M54 F59{
		
		tw (rspike ci_lower ci_upper date, lcolor(ebblue) lp(solid)) 		///
		(scatter coef date, mcolor(ebblue)) 								///
		if (cohort == "`cohort'" & outcome == "`variable'"), 				///
		legend(position(bottom) rows(1) order(1 "95% confidence interval" 	///
		2 "Point estimate")) xline(`=ym(2014,12)', lcolor(red)) 			///
		yline(0, lp(solid)) ytitle(Point estimate) 							///
		xlabel(`=ym(2009,1)'(6)`=ym(2020,12)', angle(45) labs(vsmall)) 		///
		xtitle(Date) ylabel(#10, format(%010.`dec'fc) labs(vsmall))			///
		title(`vallab', size(medium)) subtitle(Cohort: `cohort', size(medsmall))
		
		graph export "${figures}\\`variable'_`cohort'.png", replace
		
	}
	
	local ++outcome
}
