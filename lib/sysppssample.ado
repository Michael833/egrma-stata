* Systematic PPS Sampling 
* Michael Costello
* RTI International
* Version 1: April 30, 2012

program define sysppssample
	version 12
local 0 `"=`0'"'
syntax =/exp, mos(varname) seed(int) [ STRATA(varlist) weights(str) drop ]

*Setting up temporary variables, files to store data in
tempfile base new
tempvar stratum stratum_obs strat_mos skip_num class_size cumulative_min cum_mos_strat

*Sort data and issue warnings about missing data
gsort `strata' -`mos'
quietly: summarize `mos'
*  by `strata': quietly: summarize
*   if missing(`mos') display "Missing values exist in Measure of Size variable."
*	if missing(`strata') display "Missing values exist in strata variable(s)."

*Generate tempvars for size measurement calculations
by `strata': gen `cum_mos_strat' = sum(`mos')
by `strata': egen `strat_mos' = max(`cum_mos_strat')

*If user would like to return weights along with sampling units selected.
capture confirm variable weight
if !_rc {
	display as err "Variable 'weights' already exist, no replace"
}
if _rc {
	if "`weights'"=="pop" gen weight=`strat_mos'/`mos'
	if "`weights'"=="prob" gen weight=`mos'/`strat_mos' 
}

*Generating more tempvars to assist with sample selection
by `strata': gen `stratum_obs'=_n
set seed `seed'
by `strata': gen `skip_num'=`strat_mos'/`exp'
by `strata': gen `cumulative_min'= (_n==1)
	quietly: by `strata': replace `cumulative_min'=`cum_mos_strat'[_n-1]+1 if `cumulative_min'==0
egen `stratum' = group(`strata')
local num_stratum =`stratum'[_N]
capture confirm variable tosample
if !_rc {
	display as error "Overwriting variable 'tosample'"
	replace tosample=0
}
if _rc {
	gen tosample=0
}

*Creating "base" and "new" datasets
quietly: save `base'
quietly: drop _all
quietly: save `new', emptyok

*Droping obs not in the stratum in question, selecting out of that stratum, 
*and then moving those observations into the "new" dataset.
forvalues s=1/`num_stratum' {
	quietly: use `base', clear
	quietly: keep if `stratum'==`s'
	local obs_num=1+int((`skip_num'-1+1)*runiform())
	local skip_num=`skip_num' in 1
	quietly: replace tosample=tosample+1 if (`cumulative_min' <= `obs_num' & `obs_num' <= `cum_mos_strat')
	forvalues e=2/`exp' {
		local obs_num=`obs_num'+`skip_num'
		quietly: replace tosample=tosample+1 if (`cumulative_min' <= `obs_num' & `obs_num' <= `cum_mos_strat')
	}
	quietly: append using `new'
	quietly: save `new', replace
}
*Cleanup.  Drop unselected schools if desired.
gsort `strata' -`mos'
quietly: if "`drop'"=="drop" drop if tosample==0

*Display information regarding observations which were selected multiple times.
quietly: summarize tosample
if r(max)>1 {
	display in red "One or more observations were selected more than once."
	display in red "You should either double sample size at your next stage (better),"
	display in red "or double the weights at the next stage (not as good)."
}

end

*History:
*30.04.2011 -- v.1.0; program without any error messages, QC checks, etc.  
