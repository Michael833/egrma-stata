//use "Z:\Task 3 EGRA\Final Databases\Malawi\3. National EGRA Malawi 2010-2011 Wgt, T HT - without equating.dta", clear

*ToDo
* sampunit error
* in tableout, fix label when encoded.

program egranalysis
syntax using/, [noEXECute SKIPPIVotunit SKIPTABLeunit SKIPSIGbarunit]

****************************************
*  Apply settings to current data set  *
****************************************
loc all_config_settings "fluency geographics subpops treatment overs genTableByStudentFor genTableBySchoolFor sigbarVariables controls"
getegrmalocations
capture include "config.do" //user defined?
if !_rc display "Creating country-specific analysis" 
else {
	if _rc capture include "`s(config)'" //default
	if !_rc display "Creating standard analysis"
}
di ""
di ""
if _rc di "No configuration file found.  Make sure you're connected to the RTI EPS server or put a config.do file in your current working directory. Current working directory: `c(pwd)'"

foreach setting in `all_config_settings' {
	foreach variable in ``setting'' {
		capture confirm variable `variable'
		if _rc local `setting': list `setting' - variable
	}
	//di "`setting': ``setting''"
}



******************************
* Create directory structure *
******************************
capture mkdir "`using'"
if _rc di "created: `using'/"
capture file close analysis
file open analysis using "`using'/analysis.do", write replace 
di "created:     analysis.do"
capture mkdir "`using'/Contingency Tables"
if _rc di "created:     Contingency Tables/"
capture mkdir "`using'/Frequency Tables"
if _rc di "created:     Frequency Tables/"
capture mkdir "`using'/Graphs"
if _rc di "created:     Graphs/"
di "" 



*************************************
*  Create a header for the do file  *
*************************************
file write analysis `"* Analysis for `c(filename)' "' _n
file write analysis `"* Dataset version: `c(filedate)' "' _n
file write analysis `"* By `c(username)'"' _n
file write analysis `"* On `c(current_date)' | At c(current_time)"' _n
file write analysis  _n
file write analysis  _n
file write analysis `"* use `c(filename)', clear"' _n
file write analysis  _n
file write analysis  `"*Create contingency tables*"' _n
file write analysis  _n


if "`skippivotunit'"=="" { /* Create contingency tables */
	di "Writing contingency tables..."
	foreach set in `subpops' `double_subpops' {
		file write analysis `"* Create -outtables- by  `set'"' _n
		di `"	for `set'..."'
		
		*********************************
		* Single & Double subpop tables *
		*********************************
		foreach subtests in scores zeroscores fluency {
			file write analysis `"outtable ``subtests'' using "`using'/Contingency Tables/Demographic Breakdown.xlsx", subpop(`set' `treatment') over(`overs') clist(`outputvars') `svytype' `outtableExcelOptions'"' _n
		}
		file write analysis _n
	}
}


if "`skiptableunit'"=="" { /* Create frequency tables */
	* Sampling uint: Student
	local cell=3
	file write analysis "" _n(3) 
	file write analysis "* Generate frequency tables" _n(2)
	di ""
	di "Writing frequency tables..."

	foreach geo in `geographics' {
		file write analysis "* table for `geo'" _n 
		di "    for `geo'..."
		file write analysis `"tableout `geo' grade using "`using'/Contingency Tables/Demographic Breakdown.xlsx", contents((count) id) exceloptions(`tableoutExcelOptions' cell(C`cell'))"' _n
		file write analysis `"tableout `geo' using "`using'/Contingency Tables/Demographic Breakdown.xlsx", sampu(`schoolIdentifier') contents((count) id) exceloptions(`tableoutExcelOptions' cell(A`cell'))"' _n
		quietly levelsof `geo', l(offset)
		local offset: word count `offset'
		local cell=`cell'+`offset'+5
	}
	
	local column "15"
	file write analysis "* table for schools, grade, female" _n 
	file write analysis `"tableout school grade using "`using'/Contingency Tables/Demographic Breakdown.xlsx",  contents((count) id) exceloptions(`tableoutExcelOptions' cell(O4)) "' _n
	quietly levelsof grade, l(offset)
	local offset: word count `offset'
	local column=`column'+`offset'
	excelcolumn `column'
	file write analysis `"tableout school female grade using "`using'/Contingency Tables/Demographic Breakdown.xlsx", contents((count) id) exceloptions(`tableoutExcelOptions' cell(`r(column)'4))"' _n 
}

if "`skipsigbarunit'"=="" { /* Create sigbar graphs */
local graphlist ""
foreach variable in `sigbarVariables' {
	sigbar exit_interview*, dvar(`variable') control(`controls') twow(nodraw)
	graph export "/Contingency Tables/Changes in `variable'"
	sigbar `controls' dvar(`variable') twow(nodraw)
	graph export "/Contingency Tables/`variable' vs controls"
	local graphlist `"`graphlist' "/Contingency Tables/Changes in `variable'" "/Contingency Tables/`variable' vs controls""'
} 
graph combine `graphlist', saving("/Contingency Tables/All graphs.pdf") cols(1)
foreach graph in `graphlist' {
	graph use "`graph'"
	graph export "`graph'.png"
}



}


file close analysis
if "`execute'"!="noexecute" do "`using'/analysis.do"
end

program excelcolumn, rclass
	local excelcolumns A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ///
	AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ AR AS AT AU AV AW AX AY AZ ///
	BA BB BC BD BE BF BG BH BI BJ BK BL BM BN BO BP BQ BR BS BT BU BV BW BX BY BZ ///
	CA CB CC CD CE CF CG CH CI CJ CK CL CM CN CO CP CQ CR CS CT CU CV CW CX CY CZ ///
	DA DB DC DD DE DF DG DH DI DJ DK DL DM DN DO DP DQ DR DS DT DU DV DW DX DY DZ ///
	EA EB EC ED EE EF EG EH EI EJ EK EL EM EN EO EP EQ ER ES ET EU EV EW EX EY EZ
	local column: word `1' of `excelcolumns'
	return local column "`column'"
end
