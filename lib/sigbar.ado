**********************************************************************************
* SIGBAR - Creates a bar graph of the beta coefficients of significant variables *
*                                                                                *
* Handles linear and logistic regression, allows svy                             *
* By Alex Sax, Stanford University                                               *
* For RTI International                                                          * 
* 27Aug2012                                                                      *
**********************************************************************************


program define sigbar, rclass
	syntax varlist [pw aw fw] [if] [in] [, CONTrol(str) dvar(varname) alpha(real .05) LOGit SVY noLABel noGRAph GRoup(str) LEGendoptions(str) TWOWay_options(str) lsize(str) hello]
	version 11

	
	
*Set labelsize if not user defined
if "`lsize'"=="" local lsize ""
if "`svy'" != "" local `svy' = "svy:" 
if "`logit'"=="logit" local regress_type "logit"
else local regress_type "regres"
if "`control'"!="" local control_note "note(Beta coefficients controlled for: `control'"
if "`hello'"!=""{
	di in red "Hi there!"
	di in green "Now back to work."
}

* find dependent var
if "`dvar'"=="" {
	local dvar: word 1 of `varlist'
	local varlist: list varlist - dvar
}


*Run regressions
foreach variable of varlist `varlist' {
	capture `svy' `regress_type' `dvar' `control' `variable' [`weight'`exp'] `if' `in'
	if _rc==2000 di in gr "note: `dvar' vs `variable' contains no observations"
	*Test and move to significant list
	quietly: test `variable'
	if r(p)<`alpha' {
		local coefficient = _b[`variable']
		local coef_list "`coef_list' `coefficient'"
		local significant_vars "`significant_vars' `variable'"
	}
}

local n_sig_vars: word count `coef_list'
if `n_sig_vars'==0 {
	di in red "No significant variables"
	exit
}


*Gen vars to make the graph
tempvar significant_variable variable_label beta_coef variable_group
quietly: gen str `significant_variable' = ""
quietly: gen str `variable_label' = ""
quietly: gen `beta_coef' = .
quietly: gen str `variable_group' = ""

*Add the lists to the dataset so we can make the graph
**************************************************************
*   DATA will look like:                                     *
* | V1 ... Vn | significant_vars  variable_label  beta_coef  *
* | *      *  |     SIGVAR1       "first sigvar"     4.32    *
* | .      .  |        .                 .             .     *
* | .      .  |        .                 .             .     *
* | .      .  |        .                 .             .     *
* | .      .  |     SIGVARn       "last sigvar"      -7.4    *
* | .      .  |                                              *
* | .      .  |                                              *
* | *      *  |                                              *
**************************************************************


local iterator = 1
foreach variable in `significant_vars' {
	quietly: replace `significant_variable' = "`variable'" in `iterator'
	*Place label into a variable
	local this_variable_label : variable label `variable'
	quietly: replace `variable_label' = "`this_variable_label'" in `iterator'
	*Place beta_coef into variable
	local this_beta_coef : word `iterator' of `coef_list'
	quietly: replace `beta_coef' = `this_beta_coef' in `iterator'
	local ++iterator
}

*********************************************************
* Turn the groups option into a variable in the dataset *
* This will allow the user to color-code similar vars   *
* All we have to do is split                            *
*********************************************************group( school: ses electricity kerner | home: 
if "`group'"!="" {
	local word_num = 1
	while `word_num' <= wordcount("`group'") {
		// if this word defines a group
		if substr(word("`group'", `word_num'), -1, .)==":" local this_group = subinstr(word("`group'", `word_num'), ":", "", .)	
		else quietly replace `variable_group' = "`this_group'" if `significant_variable' == word("`group'", `word_num')
		local ++word_num
	}
}

*Display graph
if "`graph'" == "" {
*Display the graph if there are not groups
if "`group'" == ""{
	if "`label'" != "nolabel" {
		*And apply labels
		quietly: graph hbar (firstnm) `beta_coef' , scheme(s2color) over(`variable_label', sort(`beta_coef') ///
			label(labsize(vsmall))) asyvars showyvars cw blabel(bar, size(`lsize') format(%9.1g)) ytitle(`: variable label `dvar'' Change) ///
			title(Change in `: variable label `dvar'' by Factor) legend(off) `twoway_options' `control_note'
	}
	else {
		*Or don't
		quietly: graph hbar (firstnm) `beta_coef' ,scheme(s2color) over(`significant_variable', sort(`beta_coef') ///
			label(labsize(vsmall))) asyvars showyvars cw blabel(bar, size(`lsize') format(%9.1g)) ytitle(`: variable label `dvar'' Change) ///
			title(Change in `: variable label `dvar'' by Factor) legend(off) `twoway_options' `control_note'
	}
}
else {
	*And if there are groups
	capture graph hbar (firstnm) `beta_coef' , scheme(s2color) over(`variable_group', sort(`beta_coef')  ///
		label(nolabel)) asyvars showyvars cw over(`variable_label', sort(`beta_coef')  ///
		label(labsize(tiny))) blabel(bar, size(`lsize') format(%9.1g)) ///
		title(Change in `: variable label `dvar'' by Factor) ytitle(`: variable label `dvar'' Change) ///
		legend(on cols(1) `legendoptions') `twoway_options' `control_note'
	if _rc==2000 di as err "group option does not apply to any variables"
}
}


return local sigvars = "`significant_vars'"
return local coef_list = "`coef_list'"
local local_to_define_matrix = subinstr(substr("`coef_list'", 2,.), " ", ", ", .)
matrix coef_matrix = (`local_to_define_matrix')
matrix colnames coef_matrix = `significant_vars'
return matrix coefs = coef_matrix
end

