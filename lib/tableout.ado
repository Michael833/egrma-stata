* Shell to nicely export tables to excel
* Alex Sax
* RTI International
* April 2012

/* Notes:
Add in a missing option by forcing around the reshape. (ie recode as (999989898987blah blah) and then recode back)
*/ 
program define tableout, rclass
	syntax varlist(max=3) [if] [in] using/ [fweight pweight aweight iweight/] [, SAMPUnit(varname) contents(str) /*Missing*/ EXCELoptions(str) LABELS ]
	version 12

preserve 

local varlistlength: word count `varlist'
local clength: word count `contents'
local firstvar: word 1 of `varlist'
local secondvar: word 2 of `varlist'
local thirdvar: word 3 of `varlist'
local othervars: list varlist - firstvar 
tempvar extra
capture encode `firstvar', gen(`extra')
if !_rc {
	local firstvar "`extra'"
	local label`firstvar': variable label `extra'
}

//discard data with missing values (needed for reshape later), encode if needed.
foreach word in `firstvar' `secondvar' `thirdvar'{
	quietly drop if `word'==.                                                                  
}

//sampunit collapsing
if "`weight'"!="" {
	local weightoption "(sum) `exp'"
	local full_weight_expression "`weight' = `exp'"
}
if "`sampunit'"!="" collapse `contents' `weightoption', by(`firstvar' `secondvar' `thirdvar' `sampunit')

//table effect
collapse `contents' `full_weight_expression', by(`firstvar' `secondvar' `thirdvar')
if "`weight'"!="" quietly: drop `weight'

//reshape
foreach word in `contents' {
	//if the token starts with parentheses, it becomes our new summary stat
	if substr("`word'",1,1)=="(" {
		continue
	}
	local newcontents "`newcontents' `word'"
}
if "`secondvar'"!="" quietly: reshape wide `newcontents', i(`thirdvar' `secondvar') j(`firstvar')


//transpose data
if "`secondvar'"!="" { 
	xpose, clear varname
	*list
	// drop unneeded data
	quietly: drop if _varname=="`secondvar'"
	quietly: drop if _varname=="`thirdvar'"
	quietly: drop _varname
}
*mata: st_local("varnames", invtokens(st_varname(1..st_nvar())))
*foreach variable in `varnames' {
*	quietly: tostring `variable', replace
*}

capture label values `firstvar' label`firstvar''
//and out in xlsx
quietly: export excel "`using'", `exceloptions'


return scalar N_worksheet = r(N_worksheet)
return local worksheet_# = r(worksheet_#)
return local range_# = r(range_#)

restore

if "`labels'" == "labels" {
	local newcontents = subinstr("`contents'",")","",.)
	local newcontents = subinstr("`newcontents'","(","",.)
	table `varlist', c(`newcontents')
	preserve 
	tempvar trashvar
	gen `trashvar'=_n
	local firstvar: word 1 of `varlist'
	collapse (count) `trashvar' , by(`firstvar')
	list `firstvar', noo clean
	restore
}
end
