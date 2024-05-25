
global main "C:\Users\Pablo Uribe\Desktop\BanRep\Pensions"
global figures "${main}\Graphs"
global tables "${main}\Tables"

global cohorts M50 M54 F55 F59

set graphics off

use "${tables}\RIPS_results.dta", clear

encode outcome, gen(en_outcome)
label def labout 1 "Cardiovascular" 2 "Chronic disease" 					///
3 "Consultation with psychologist" 4 "Probability of consultation" 			///
5 "Mental diagnosis" 6 "Stress" 7 "Probability of hospitalization" 			///
8 "Infarct" 9 "Number of hospitalizations" 	10 "Number of consultations" 	///
11 "Number of procedures" 12 "Number of services" 13 "Number of ER visits" 	///
14 "Multi-morbidity index" 15 "Probability of procedures" 					///
16 "Probability of health service" 17 "Probability of ER visit"
label val en_outcome labout

gen coef_plus = coef + control

gen li_plus = ci_lower + control
gen hi_plus = ci_upper + control

levelsof outcome, local(outcomes)
local outcome = 1
foreach variable in `outcomes'{
	
	if inrange(`outcome', 9, 13){
		local dec = 2
	}
	else{
		local dec = 3
	}
	
	local vallab : label (en_outcome) `outcome'
	
	foreach cohort of global cohorts{
		
		foreach bw in 11 22{
			qui sum age if cohort == "`cohort'"
			local min = r(min)
			local max = r(max)
			
			tw (connected control age, color(gray) lpattern(dash)) 				///
			(rcap li_plus hi_plus age, lcolor(ebblue) lp(solid)) 				///
			(connected coef_plus age, color(ebblue)) 							///
			if (cohort == "`cohort'" & outcome == "`variable'" & bw == `bw'),	///
			legend(position(bottom) rows(1) order(3 "Mean + Point estimate" 	///
			1 "Control's mean" 2 "95% Confidence interval")) 					///
			ytitle(Point estimate) xlabel(`min'(1)`max') xtitle(Age)			///
			ylabel(#10, format(%010.`dec'fc) labs(vsmall)) 						///
			title(`vallab', size(medium)) 										///
			subtitle(Cohort: `cohort'; Bandwidth: `bw' weeks, size(medsmall))
			
			graph export "${figures}\age\\`variable'_`cohort'_`bw'.png", replace
		}
	}
	
	local ++outcome
}
