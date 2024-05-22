
global main "C:\Users\Pablo Uribe\Desktop\BanRep\Pensions"
global figures "${main}\Graphs"
global tables "${main}\Tables"

set graphics off

use "${tables}\RIPS_results.dta", clear

encode outcome, gen(en_outcome)
label def labout 1 "Cardiovascular" 2 "Chronic disease" 3 "Consultation with psychologist" 4 "Probability of consultation" 5 "Stress" 6 "Probability of hospitalization" 7 "Infarct" 8 "Number of hospitalizations" 9 "Number of consultations" 10 "Number of procedures" 11 "Number of services" 12 "Number of ER visits" 13 "Multi-morbidity index" 14 "Probability of procedures" 15 "Probability of health service" 16 "Probability of ER visit"
label val en_outcome labout

levelsof outcome, local(outcomes)
local outcome = 1
foreach variable in `outcomes'{
	
	if inrange(`outcome', 8, 12){
		local dec = 0
	}
	else{
		local dec = 3
	}
	
	local vallab : label (en_outcome) `outcome'
	
	foreach cohort in M50 F55{
		
		tw (rspike ci_lower ci_upper year, lcolor(ebblue) lp(solid)) 		///
		(scatter coef year, mcolor(ebblue)) 								///
		if (cohort == "`cohort'" & outcome == "`variable'"), 				///
		legend(position(bottom) rows(1) order(1 "95% confidence interval" 	///
		2 "Point estimate")) xline(2010, lcolor(red)) 						///
		yline(0, lp(solid)) ytitle(Point estimate) 							///
		xlabel(2009(1)2011) xtitle(Year) 									///
		ylabel(#10, format(%010.`dec'fc) labs(vsmall)) 						///
		title(`vallab', size(medium)) subtitle(Cohort: `cohort', size(medsmall))
		
		graph export "${figures}\\`variable'_`cohort'.png", replace
		
	}
	
	foreach cohort in M54 F59{
		
		tw (rspike ci_lower ci_upper year, lcolor(ebblue) lp(solid)) 		///
		(scatter coef year, mcolor(ebblue)) 								///
		if (cohort == "`cohort'" & outcome == "`variable'"), 				///
		legend(position(bottom) rows(1) order(1 "95% confidence interval" 	///
		2 "Point estimate")) xline(2014, lcolor(red)) 						///
		yline(0, lp(solid)) ytitle(Point estimate) 							///
		xlabel(2009(1)2020, angle(45) labs(vsmall)) 						///
		xtitle(Year) ylabel(#10, format(%010.`dec'fc))						///
		title(`vallab', size(medium)) subtitle(Cohort: `cohort', size(medsmall))
		
		graph export "${figures}\\`variable'_`cohort'.png", replace
		
	}
	
	local ++outcome
}
