/*************************************************************************
 *************************************************************************			       	
	        Pensions Replication master do
			 
1) Created by: Pablo Uribe
			   Yale University
			   p.uribe@yale.edu
				
2) Date: July 2024

3) Objective: Replicate all the paper's exhibits. Exact replicability is
              ensured by using constant packages versions
              
*************************************************************************
*************************************************************************/	

version 17

cap which repkit  
if _rc == 111{
    ssc install repkit
}

****************************************************************************
* Globals
****************************************************************************

* Set path to reproducibility package (where ado and code are located)
if inlist("`c(username)'", "Pablo Uribe", "pu42") {
    
    global root	"~\Documents\GitHub\Pensions"
    
}
else {
    
    global root	"Z:\Christian Posso\_banrep_research\proyectos\Pensions"
    
}

cap mkdir "${root}\Logs"
cap mkdir "${root}\Output"

* Point adopath to the ado folder in the reproducibility package
repado, adopath("${root}\ado") mode(strict)

* Code folder within rep package
global do_files "${root}\code"


****************************************************************************
* Run all do files
****************************************************************************

*** Census balance
*do "${do_files}\Step 1 - Cleanup.do"
*do "${do_files}\Step 2 - Estimation.do"

*** Main results
*do "${do_files}\Step 1 - Master dataset and exploratory analysis.do"
*do "${do_files}\Step 2 - Master descriptive stats.do"               
*do "${do_files}\Step 3.1 - PILA consolidation.do"                   
*do "${do_files}\Step 3.2 - Merge with RIPS.do"                      
*do "${do_files}\Step 3.2.1 - RIPS dataset.do"                       
*do "${do_files}\Step 4.1 - PILA estimation.do"                      
*do "${do_files}\Step 4.2 - RIPS estimation.do"                      
*do "${do_files}\Step 5.1 - PILA plots.do"                           
*do "${do_files}\Step 5.2 - RIPS plots.do"

