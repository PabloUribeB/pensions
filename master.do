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
* Set path for original datasets in BanRep
if "`c(hostname)'" == "SM201439" global pc "C:"
else global pc "\\sm093119"


global data         "${pc}\Proyectos\Banrep research\Pensions\Data"
global data_master  "${pc}\Proyectos\PILA master"
global pila_og      "\\sm134796\D\Originales\PILA\1.Pila mensualizada\PILA mes cotizado"
global ipc          "\\sm037577\D\Proyectos\Banrep research\c_2018_SSO Servicio Social Obligatorio\Project SSO Training\Data"
global urgencias    "${pc}\Proyectos\Data"
global RIPS         "\\sm134796\E\RIPS\Stata"
global RIPS2        "\\wmedesrv\gamma\rips"

* Set path to reproducibility package (where ado and code are located)
if inlist("`c(username)'", "Pablo Uribe", "pu42") {
    
    global root	    "~\Documents\GitHub\Pensions"
    global ext_data "C:\Users\\`c(username)'\Documents\GitHub\pensions\Data"
    local  run =    "external"
    
}

if "`c(username)'" == "cpossosu" {

    global root	 "\\wmedesrv\GAMMA\Christian Posso\_banrep_research\proyectos\pensions"
    local  run = "banrep"

}
	
else{

    global root	 "Z:\Christian Posso\_banrep_research\proyectos\pensions"
    local  run = "banrep"

}

cap mkdir "${root}\Logs"
cap mkdir "${root}\Tables"
cap mkdir "${root}\Graphs"
cap mkdir "${root}\Output"

* Point adopath to the ado folder in the reproducibility package
repado, adopath("${root}\ado") mode(strict)

* Folders within rep package
global do_files "${root}\code"
global tables   "${root}\Tables"
global graphs   "${root}\Graphs"
global logs     "${root}\Logs"
global output   "${root}\Output"

****************************************************************************
* Run all do files
****************************************************************************


*** Census balance
if "`run'" == "external" { // Data not in BanRep, so only run in external PC

    *do "${do_files}\2005 census\Step 1 - Cleanup.do"
    do "${do_files}\2005 census\Step 2 - Estimation.do"
    
}


*** Main results
if "`run'" == "banrep" { // Data only in BanRep
    
    *do "${do_files}\Step 1 - Master dataset and exploratory analysis.do"
    *do "${do_files}\Step 2 - Master descriptive stats.do"
    do "${do_files}\Step 3.1 - PILA consolidation.do"
    *do "${do_files}\Step 3.2 - Merge with RIPS.do"
    *do "${do_files}\Step 3.2.1 - RIPS dataset.do"
    *do "${do_files}\Step 4.1 - PILA estimation.do"
    *do "${do_files}\Step 4.2 - RIPS estimation.do"
    
}

*do "${do_files}\Step 5.1 - PILA plots.do"
*do "${do_files}\Step 5.2 - RIPS plots.do"

