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

clear all
version 17

cap which repkit  
if _rc == 111{
    ssc install repkit
}

****************************************************************************
* Globals
****************************************************************************
* Set path for original datasets in BanRep

global pila_og      "\\sm134796/D/Originales/PILA/1.Pila mensualizada/PILA mes cotizado"
global ipc          "\\sm037577/D/Proyectos/Banrep research/c_2018_SSO Servicio Social Obligatorio/Project SSO Training/Data"
global RIPS         "\\sm209696/E/RIPS/Stata"
global RIPS2        "\\wmedesrv/gamma/rips"

* Set path to reproducibility package (where ado and code are located)
if inlist("`c(username)'", "Pablo Uribe", "pu42") {
    
    global root	    "C:/Users\\`c(username)'/Documents/GitHub/pensions"
    global ext_data "${root}/Data"
    local  run =    "external"
    
}

else if "`c(username)'" == "cpossosu" {
    
    global server "\\wmedesrv/GAMMA/Christian Posso/_banrep_research/proyectos"
    global root	  "${server}/pensions"

    local  run = "banrep"

}
	
else{
    
    global server "Z:/Christian Posso/_banrep_research/proyectos"
    global root	 "${server}/pensions"
    local  run = "banrep"

}

global data         "${root}/Data"
global data_master  "${root}/Data"
global chronic      "${server}/More_than_a_Healing/Data"
global urgencias    "${server}/SOMEWHERE/Data" // Queda pendiente que Sofía me avise

cap mkdir "${root}/Logs"
cap mkdir "${root}/Tables"
cap mkdir "${root}/Graphs"
cap mkdir "${root}/Output"

* Point adopath to the ado folder in the reproducibility package
repado, adopath("${root}/ado") mode(strict)

* Folders within rep package
global do_files "${root}/code"
global tables   "${root}/Tables"
global graphs   "${root}/Graphs"
global logs     "${root}/Logs"
global output   "${root}/Output"

****************************************************************************
* Run all do files
****************************************************************************


*** Census balance
if "`run'" == "external" { // Data not in BanRep, so only run in external PC

    *do "${do_files}\2005 census\Step 1 - Cleanup.do"
    do "${do_files}/2005 census/Step 2 - Estimation.do"
    
}


*** Main results
if "`run'" == "banrep" { // Data only in BanRep
    
    *do "${do_files}/Step 1 - Master dataset and exploratory analysis.do"
    *do "${do_files}/Step 3.1 - PILA consolidation.do"
    *do "${do_files}/Step 3.1.1 - Master sample for RIPS.do"
    *do "${do_files}/Step 3.2 - Merge with RIPS.do"
    *do "${do_files}/Step 3.2.1 - RIPS dataset.do"
    do "${do_files}/Step 4 - Master descriptive stats.do"
    *do "${do_files}/Step 4.1 - PILA estimation.do"
    *do "${do_files}/Step 4.2 - RIPS estimation.do"
    
}

*do "${do_files}/Step 5.1 - PILA plots.do"
*do "${do_files}/Step 5.2 - RIPS plots.do"

