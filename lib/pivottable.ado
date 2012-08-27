	  
*****************************************************************
* pivottable - Pivot table program with export excel capability	*
*  		Alex Sax, asax@stanford.edu								*
*  		RTI International, EPS									*
*  																*
* pivottable works in three stages: load, calculate, clean.  It *
* is written 98% in STATA with a few lines in MATA that will be *
* thoroughly commented.											*
*****************************************************************

	  

program pivottable, eclass
version 12
syntax varlist using/ [fw pw iw] [if] [in] , [ Clist(str) SUBpop(str) Over(str) svy iid conf(real -1) MAINstat(str) DECimalplaces(int -1) Missing ///
      SHeet(passthru) cell(passthru) SHEETMODify SHEETREPlace FIRSTrow(passthru) NOLabel replace DATEstring(passthru) locale(passthru) drop(str) ///
	  do1(str) do2(str) do3(str) do4(str) do5(str) do6(str) do7(str) do8(str) do9(str) do10(str) do11(str) do12(str) do13(str) do14(str) do15(str)]
{/* LOAD STAGE */
*****************************************************************
* LOAD STAGE - Set defaults and parse user input				*
*																*
* Check which options the user required, save them in locals 	*
* that will be used later in the program						*
*****************************************************************

	  
*Set defaults
local 									default_main 				"mean"	  	  
local 									default_statistics 			"mean sd count"	  
local 									_all_should_equal 			"min max mean se sd ci count n pi 5num"
local 									default_conf  				.95
local 									default_decimal_places 		"2"


//Load defaults
if "`mainstat'"=="" local 				mainstat					"`default_main'" 
if "`if'"=="" local 					if 							"if 1" 
if "`weight'"=="iweight" local 			weight						"fweight"
if "`conf'"=="-1" local 				conf 						"`default_conf'"
if "`decimalplaces'"=="-1" local 		decimalplaces 				"`default_decimal_places'"
if "`clist'"=="" local 					clist 						"`default_statistics'"
local clist = regexr("`clist'","_all", "`_all_should_equal'") // If the user wanted all summary statistics

//Parse which stats the user required by iterating over clist and 
// tagging required stats with a 1
foreach stat in `clist' {
  local use_`stat' = "1"
  
}
//Set the rest equal to 0
foreach stat in use_min use_max use_mean use_se use_sd use_ci use_n use_count use_pi use_5num use_tstats use_effects use_N {
  if "``stat''"!="1" local `stat' = "0"
}
//And allow the user to use both N and n to get poulation estimates
if `use_N' local use_n "1"

//Set up our locals
local analysisvars "mean_ se_ sd_ count_ N_ min_ pcntile25_ pcntile50_ pcntile75_ max_ ci_lower_ ci_upper_ pi_lower_ pi_upper_ t_stat_ p_value_"
local half_conf = (1-`conf')/2            //used for creating the confidence interval
local loconfidence = (1-`conf')/2*100     //used in the _pctile command for genning prediction interval
local hiconfidence = 100-`loconfidence'   //used in the _pctile command for genning prediction interval
local conf_level = `conf'*100             //used in lincom

*************************************************
* Find the levels in our last subpop variable
*   This is for determining when to run the 
*   lincom (tstat) command
*************************************************
if "`subpop'"=="" local subpoplen "1"
else {
  local subpoplen: word count `subpop'
  local lastsubpop: word `subpoplen' of `subpop'
  quietly levelsof `lastsubpop', local(l_lastsubpop) `missing'
  local subpoplen: word count `l_lastsubpop'
  local abl_subpop: list subpop - lastsubpop
  
  if "`subpoplen'"=="1" & `use_tstats' {
    di as err "Only one group in `lastsubpop'"
	scalar `use_tstats' = 0
  }
}

// Create group variables to uniquely identify all our subpops
tempvar group overgroup subgroup last_subgroup_index group_all_but_last_subpop
quietly egen `group' = group(`over' `subpop'), `missing'
quietly levelsof `group', local(l_group)
quietly egen `overgroup' = group(`over'), `missing'
quietly levelsof `overgroup', local(l_overgroup)
quietly egen `subgroup' = group(`subpop'), `missing'
quietly levelsof `subgroup', local(l_subgroup)
quietly egen `group_all_but_last_subpop' = group(`abl_subpop'), `missing'
quietly levelsof `group_all_but_last_subpop', local(l_abl_subpop)
quietly egen `last_subgroup_index' =  group(`lastsubpop'), `missing'

//masterfiles 
tempfile mastertable demographictable meantable ttable pcttable

*****************************************************************
* Create a database that matches our generated (and numeric) ID *
* variables to the user specified identifier variables.	        *
*****************************************************************
preserve
local var1: word 1 of `varlist' // We just need to collapse by a variable
collapse (count) `var1', by(`group' `overgroup' `subgroup' `group_all_but_last_subpop' `last_subgroup_index' `over'  `subpop')
if "`missing'"!="missing" quietly drop if `group'==. // drop groups that are missing identifiers
quietly drop `var1' 
local n_groups = _N //make a note of the number of subpops
quietly save "`demographictable'", replace
restore
}


{/* CALCULATION STAGE */
*****************************************************************
* CALCULATION STAGE - Generate summary stats for each subgroup 	*
*																*
* The calculation stage is by far the most complex stage. 		*
* pivottable calculates summary stats for each subgroup by 		*
* nested loops (3 of em). See below.							*
*****************************************************************

*****************************************************************
* LOOPS in calculation stage									*
*																*
* 																*
* SUBTEST														*
*		OVER													*
*			+-SUBPOP-											*
*			|													*
*			|	Summary statistics using:						*
*			|	Mean function (mean, CI, N, count, se)			*
*			|	Estats function (sd)							*
*			|	_Pctile function (for percentiles and PI)		*
*			|													*
*			+--END---											*
*																*
*			+-FIRST FEW SUBPOP VARS-							*
*			|	Calculate mean, over(last subpop variable)		*
*			|													*
*			|	+-LAST SUBPOP VARIABLE----						*
*			|	|												*
*			|	|	Do lincom to calculate tstats and pvalue	*
*			|	|												*
*			|	+--------END----------							*
*			|													*
*			+--END---											*
*		END														*
*END															*
*																*
* 																*
*****************************************************************

foreach subtest in `varlist' {
	*************************************************************
	* pivottable uses postfiles to save statistics, so here we 	*
	* just check if those postfiles are already open, and if 	*
	* they are, we just close and reopen them.					*
	*************************************************************
	capture postfile pcttable `overgroup' `subgroup' min_ pi_lower_ pcntile25_ pcntile50_ pcntile75_ pi_upper_ max_ using "`pcttable'", replace
	if _rc {
		capture postclose pcttable 
		capture postclose meantable
		capture postclose ttable
		quietly postfile pcttable `overgroup' `subgroup' min_ pi_lower_ pcntile25_ pcntile50_ pcntile75_ pi_upper_ max_ using "`pcttable'", replace
	}
	quietly postfile meantable `overgroup' `subgroup' N_ df mean_ se_ sd_ count_ using "`meantable'", replace
	quietly postfile ttable `overgroup' `group_all_but_last_subpop' `last_subgroup_index' t_stat_ p_value_ using "`ttable'", replace 
	
	
	foreach level in `l_overgroup' {
		foreach subgroup_level in `l_subgroup' {
			  if `use_mean' | `use_se' | `use_sd' | `use_ci' | `use_n'  {
				*********************************************************************  
				* Use the mean and estats function to find a bunch of summary stats *
				********************************************************************* 
					*****************************************************************************
					* Calculate the mean function differently based on what the data looks like *
					*****************************************************************************
					if "`svy'"=="svy" & "`iid'"=="iid"	 	capture svy, subpop(`subgroup' if `subgroup'==`subgroup_level'): `mainstat' `subtest' `if' & `overgroup'==`level' [`in']
					else if "`svy'"=="svy"  				capture svy, subpop(`subgroup' if `overgroup'==`level' & `subgroup'==`subgroup_level'): `mainstat' `subtest' `if' [`in']
					else 									capture `mainstat' `subtest' [`weight'`exp'] `if' & `overgroup'==`level'  & `subgroup'==`subgroup_level' [`in']
					if _rc==461 | _rc==2000 | _rc==111 continue //If no observations in the subpop, then dont save anything!
					if "`mainstat'"=="mean" quietly estat sd // if the user wants SD

							
					//Save N_ for subpop population
					if "`svy'"=="svy" {
					  local n =  e(N_subpop)
					}
					else { 
					  matrix junk = e(_N)
					  local n =  junk[1,1]
					}
					
					//Save count_ (sample size)
					matrix junk = e(_N)
					local subpop_count  =  junk[1,1]
					
					//Save SE using mata.
					// Take the co-variance matrix e(V), and take the squareroot of each of the elements
					// Now take the new co-standard-err matrix and extract the diagonal, giving us a 
					// standard-error vector. Save this into a stata matrix called SE
					mata: st_matrix("se",diagonal(st_matrix("e(V)")':^.5))
					
					
					//Save SD
					if "`mainstat'"=="mean" & "`weight'"!="aweight"{
					  matrix sd = r(sd)'
					}
					
					//Save the mean
					matrix mean = e(b)		
					post meantable  (`level') (`subgroup_level') (`n') (e(df_r)) (mean[1,1]) (se[1,1]) (sd[1,1]) (`subpop_count')
			  }
			  
		  

				
			  if `use_pi' | `use_5num' | `use_min' | `use_max'{
				************************************************************  
				* Use the _pctile command to find the PI and 5 num summary *
				************************************************************  
				if "`svy'"=="svy"{
				  quietly: svyset
				  if "`mainstat'"=="ratio" quietly _pctile `evaluated_ratio' [`r(wtype)'`r(wexp)'] `if' & `overgroup'==`level'  & `subgroup'==`subgroup_level' [`in'], p(0.00000000000001, `loconfidence',25,50,75,`hiconfidence',99.99999999999999)
				  else quietly _pctile `subtest' [`r(wtype)'`r(wexp)'] `if' & `overgroup'==`level'  & `subgroup'==`subgroup_level' [`in'], p(0.00000000000001, `loconfidence',25,50,75,`hiconfidence',99.99999999999999)
				}
				else{
				  if "`mainstat'"=="ratio" quietly  _pctile `evaluated_ratio'[`weight'`exp'] `if' & `overgroup'==`level'  & `subgroup'==`subgroup_level' [`in'], p(0.00000000000001, `loconfidence',25,50,75,`hiconfidence',99.99999999999999)
				  else quietly _pctile `subtest' [`weight'`exp'] `if' & `overgroup'==`level'  & `subgroup'==`subgroup_level' [`in'], p(0.00000000000001, `loconfidence',25,50,75,`hiconfidence',99.99999999999999)
				}
				post pcttable  (`level') (`subgroup_level') (r(r1)) (r(r2)) (r(r3)) (r(r4)) (r(r5)) (r(r6)) (r(r7)) 
			  }
		}
	
		if `use_tstats' & "`subpop'"!="" {
			********************************************************************
			* If we want tstats we must do the test by level, using the lincom *
			* function. After tunning each level of the test, we save the      *
			* in a post ttable                                                 *
			********************************************************************
			foreach sublevel in `l_abl_subpop' {
				*****************************************************************************
				* Calculate the mean function differently based on what the data looks like *
				***************************************************************************** 
				if "`svy'"=="svy" & "`iid'"=="iid"	 	capture svy, subpop(`group_all_but_last_subpop' if `group_all_but_last_subpop'==`sublevel'): `mainstat' `subtest' `if' & `overgroup'==`level' [`in'], over(`last_subgroup_index')
				else if "`svy'"=="svy"  				capture svy, subpop(`group_all_but_last_subpop' if `group_all_but_last_subpop'==`sublevel' & `overgroup'==`level'): `mainstat' `subtest' `if' [`in'], over(`last_subgroup_index')
				else 									capture `mainstat' `subtest' [`weight'`exp'] `if' & `group_all_but_last_subpop'==`sublevel' & `overgroup'==`level' [`in'], over(`last_subgroup_index')
				if _rc==461 | _rc==2000 | _rc==111 continue //If no observations in the subpop
				forvalues groupnum = 1/`subpoplen' {
					capture lincom [`subtest']1 - [`subtest']`groupnum', level(`conf_level')
					if !_rc post ttable (`level') (`sublevel') (`groupnum') (abs(r(estimate))/r(se)) (2*ttail(r(df), (abs(r(estimate))/r(se))))
				} 
			}
		}			
	}
  
	preserve
	postclose pcttable
	postclose meantable
	postclose ttable
	use "`meantable'", clear
	quietly: gen ci_lower_ = mean_-se_*invttail(df,`half_conf') 
	quietly: gen ci_upper_= mean_+se_*invttail(df,`half_conf')

	quietly drop df
	quietly save `meantable', replace
	restore 
	
	
	
	***************************
	* Now combine the tables *
	***************************
	preserve
	clear
	capture use "`demographictable'", clear
	capture merge 1:1 `overgroup' `subgroup' using "`meantable'", nogen
	capture merge 1:1 `overgroup' `group_all_but_last_subpop' `last_subgroup_index' using "`ttable'", nogen
	capture merge 1:1 `overgroup' `subgroup' using "`pcttable'", nogen
	gen str244 subtest = "`subtest'"
	capture append using "`mastertable'"
		capture mi unset, asis
	quietly save "`mastertable'", replace 
	restore
}

***********************************************
* Merge calculated variables and demographics *
* Then reshape data                           *
***********************************************
preserve 
quietly use "`mastertable'", clear
*******************************************************
* Create ID which will allow us to order the subtests *
*******************************************************
tempvar id
quietly summarize `group'
quietly gen `id'=_n
quietly replace `id' = `id' - 1 if floor(`id'/r(max)) == `id'/r(max)
quietly replace `id' = floor(`id'/r(max))

//Use only the analysisvars that the user requested
unab vars: _all
local analysisvars: list analysisvars & vars
drop `overgroup'
order `analysisvars'

if `use_effects' {
	//Find number of groups in over
	local lastoverlen: word count `over'
	local lastover : word `lastoverlen' of `over'
	quietly levelsof `lastover', local(l_lastover) `missing'
	local lastoverlen: word count `l_lastover'
	if "`lastoverlen'"=="1"{
		di as err "Only one group in `lastover'"
		break
	}
	//Reshape by only the last variable in over
	local list_abl_over: list over - lastover
	quietly egen ablastoverindex = group(`list_abl_over'), `missing'
	quietly egen lastoverindex = group(`lastover'), `missing'
	quietly egen lastsubpopindex = group(`lastsubpop'), `missing'
	drop `group' `over'
	quietly reshape wide `analysisvars' , i( subtest ablastoverindex `subgroup') j(lastoverindex)
	gsort -`id'  ablastoverindex `subgroup'
	local N=_N
	local offset = 0

	//Now calculate effect sizes
	forvalues popinlastover = 2/`lastoverlen'{
		quietly gen pcnt_increase_`popinlastover' = .
		quietly gen pooled_var_`popinlastover' =.
		quietly gen effect_size_`popinlastover' =.
		forvalues x = 1/`N' {
			****************************************************************
			*  Use Cohen's D calculation if the last variable is treatment *
			****************************************************************
			if "`lastsubpop'"=="treatment" {
				if lastsubpopindex[`x']==1 {
					local offset=1
					continue
				}
				else if lastsubpopindex[`x'-`offset']==1 {
					quietly replace pcnt_increase_`popinlastover' = ((mean_`popinlastover'-mean_1)-(mean_`popinlastover'[`x'-`offset']-mean_1[`x'-`offset']))/mean_1 in `x'
					quietly replace pooled_var_`popinlastover' = (((count_1-1)*sd_1^2+(count_`popinlastover'-1)*sd_`popinlastover'^2 + (count_1[`x'-`offset']-1)*sd_1[`x'-`offset']^2+(count_`popinlastover'[`x'-`offset']-1)*sd_`popinlastover'[`x'-`offset']^2) ///
									/(count_1+count_`popinlastover'+count_1[`x'-`offset']+count_`popinlastover'[`x'-`offset']-4))^.5 in `x'
					quietly replace effect_size_`popinlastover' = ((mean_`popinlastover' - mean_1)-(mean_`popinlastover'[`x'-`offset'] - mean_1[`x'-`offset']))/pooled_var_`popinlastover' in `x'
					local ++offset
				}
			}
		}
		********************************************************
		*  Otherwise use the standard effect size calculation  *
		********************************************************
		if "`lastsubpop'"!="treatment" {
			quietly replace pcnt_increase_`popinlastover' = (mean_`popinlastover'-mean_1)/mean_1
			quietly replace pooled_var_`popinlastover' = ((count_1-1)*sd_1^2+(count_`popinlastover'-1)*sd_`popinlastover'^2) ///
								/(count_1+count_`popinlastover'-2)^.5
			quietly replace effect_size_`popinlastover' = (mean_`popinlastover' - mean_1)/pooled_var_`popinlastover'
		}
				
	}
	drop pooled_var*
	local analysisvars "`analysisvars' pcnt_increase_ effect_size_"
	quietly reshape long `analysisvars', i(subtest ablastoverindex `subgroup') j(lastoverindex)	
	quietly drop if mean_ == . //Reshape can create some problems, so we need to drop missings that we create
	quietly egen `overgroup' = group(ablastoverindex lastoverindex), `missing'
	drop ablastoverindex lastoverindex lastsubpopindex
}
drop `subgroup' `group_all_but_last_subpop' `last_subgroup_index'
quietly egen `subgroup' = group(`subpop' subtest), `missing'
capture egen `overgroup' = group(`over'), `missing'
capture drop `over' `group' 
format `analysisvars' %9.`decimalplaces'fc 
quietly reshape wide `analysisvars', i(`subgroup') j(`overgroup')
gsort -`id' `subgroup'
drop `subgroup' `id'
quietly recode count* (.=0) //because there really are 0 people in the sample - not an unknown amount

**************************************************************
* At the bottom of the dataset put the method of calculation *
**************************************************************
local setlength=_N+5
if `use_effects' & "`lastsubpop'"=="treatment" {
    quietly set obs `setlength'
	quietly gen var = ""
	quietly replace var="The effects size calculations in the table above use Cohen's D, controlling for the control group in the effect size calculation of the treatment group(s)." in `setlength'
}
	else if `use_effects' {
    quietly set obs `setlength'
	quietly quietly gen var= ""
	quietly replace var = "The effects size calculations in the table above use Cohen's D, but only assess the difference between phases without controlling by some kind of control group." in `setlength'
}

**************************
* Drop uneeded variables *
**************************
quietly compress _all
if `use_mean'==0 capture drop mean_*
if `use_se'==0 capture drop se_*
if `use_sd'==0 capture drop sd_*
if `use_5num'==0 capture drop pcntile*_*
if `use_5num'==0 & `use_min'==0 capture drop min_*
if `use_5num'==0 & `use_max'==0 capture drop max_*
if `use_count'==0 capture drop count_*
if `use_n'==0 capture drop N_*
if `use_pi'==0 capture drop pi_upper_* pi_lower_*
if `use_ci'==0 capture drop ci_upper_* ci_lower_*
if `use_tstats'==0 capture drop t_stat_* p_value_*
if `use_effects'==0 capture drop pcnt_increase_* effect_size_*
order subtest `subpop'  
if "`order'"!="" order  `order'
if "`drop'"!="" drop  `drop'

********************************************
* Allow user to execute code before saving *
********************************************
local i "1"
while "`do`i''"!="" {
  `do`i''
  local ++i
}





*****************************
* Return values to the user *
*****************************
ereturn post
ereturn local cmd "pivottable `0'" 

**********************************************
* Save the file, depending on file extention *
**********************************************
if regexm("`using'","\.dta$") { 				// Save DTA format
  save "`using'", `replace'
  ereturn local open = `"use "`using'", clear"'
}
else if regexm("`using'","\.csv$") {  			// Save CSV format
  outsheet using "`using'", `replace'
  ereturn local open = `"insheet using "`using'", clear"'
}
else if regexm("`using'","\.xlsx$|\.xls$") {  	// Save using XLS or XLSX format
  //Defaults
  if "`replace'"=="" & "`sheet'"=="" & "`cell'"=="" & "`sheetmodify"=="" & "'"=="" & "`sheetreplace'"=="" & "`firstrow'"=="" & "`nolabel'"=="" & "`datestring'"=="" & "`locale'"=="" {
    local sheet "sheet(sheet1)"
	local sheetreplace "sheetreplace"
	local firstrow "firstrow(variables)"
  }
  export excel using "`using'", `replace' `sheet' `cell' `sheetmodify ' `sheetreplace' `firstrow' `nolabel' `datestring' `locale'
  ereturn local open = `"import excel using "`using'", clear"'
}
else  {
  save "`using'.dta", `replace'
  ereturn local open = `"use "`using'", clear"'
}




end
