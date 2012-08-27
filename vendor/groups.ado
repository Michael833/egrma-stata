*! NJC 1.2.5 26 January 2011 
* NJC 1.2.4 24 January 2011 
* NJC 1.2.3 21 January 2010 
* NJC 1.2.2 20 January 2010 
* NJC 1.2.1 11 April 2007
* NJC 1.2.0 30 March 2007
* NJC 1.1.1 2 August 2003 
* NJC 1.1.0 31 July 2003 
* NJC 1.0.0 27 July 2003 
program groups, sort byable(recall) 
	version 8 
	syntax varlist [if] [in] [fweight aweight/] ///
	[,  NOObs SUBVARname SUM Compress LABvar(varname) *  ///
	FILLin MISSing SHow(str) showhead(str asis) SELect(str) Order(str) ///
	FORMat(str) nby(numlist int >0) ge lt REVerse ] 
	
	// ignore subvarname noobs labvar() (compulsory default) 

	// what to use 
	if "`missing'" == "" marksample touse, strok 
	else marksample touse, novarlist 
	
	qui count if `touse' 
	if r(N) == 0 error 2000 

	tempvar freq Freq rfreq percent Percent rpercent ///
		vfreq vpercent Vpercent rvpercent tag 

	// show option 
	if "`show'" == "none" { 
		// OK 
	} 	
	else if "`show'" != "" { 
		foreach w in `show' { 
			local OK 0 
			if lower(substr("`w'",1,1)) == "r" { 
				local w = lower("`w'") 
			} 	
			foreach s in freq Freq rfreq percent Percent rpercent vpercent Vpercent rvpercent { 
				if "`w'" == substr("`s'",1,length("`w'")) { 
					local OK 1 
					local Show "`Show'``s'' " 
					local SHOW "`SHOW'`s' " 
				}
			}
			if !`OK' { 
				di as inp "`show' " ///
				   as err "invalid argument for " /// 
				   as inp "show()"
				exit 198 
			} 	
		}
	}	
	else { 
		if `: word count `varlist'' > 1 { 
			local Show "`freq' `percent'"
		} 	
		else local Show "`freq' `percent' `Percent'"
	}

	if `"`showhead'"' != "" { 
		if `: word count `showhead'' != `: word count `Show'' { 
			di as err "showhead() does not match show()" 
			exit 198 
		}
	} 	
	
	local Cum "`Freq' `rfreq' `Percent' `rpercent' `Vpercent' `rvpercent'" 
	local nCum `: word count `: list Cum & Show'' 

	// select option 
	if "`select'" != "" {
		if real("`select'") < . { 
			capture confirm integer number `select' 
			if _rc { 
				di as inp "`select' " ///
				   as err "invalid argument for " /// 
				   as inp "select()" 
				exit 198 
			} 	
			
			if `select' == 0 exit 0 
			local Selectint 1
		} 
		else {
			tokenize "`select'", parse(" ><=") 
			local w "`1'"  
			local W : subinstr local select "`w'" ""
			
			if lower(substr("`w'",1,1)) == "r" { 
				local w = lower("`w'") 
			} 	

			local OK 0 
			foreach s in freq percent Freq Percent rfreq ///
				rpercent vpercent Vpercent rvpercent { 
				if "`w'" == substr("`s'",1,length("`w'")) { 
					local OK 1 
					local Select "``s''" 
					continue, break 
				}
			} 	
			
			// selection should specify an equality or inequality 
			qui count if 1 `W' 
			if _rc | !`OK' { 
				di as inp "`select' " ///
				   as err "invalid argument for " /// 
				   as inp "select()"
				exit 198 
			} 	

			local Selectint 0 
		} 	
	}

	// order option 
	if "`order'" != "" { 
		if `: word count `order'' > 1 { 
			di as err "invalid " as inp "order()" as err "option"
			exit 198 
		} 
		
		local orderlist "h hi hig high l lo low" 
		if !`: list order in orderlist' { 
			di as inp "`order' " ///
			   as err "invalid argument for " /// 
			   as inp "order()"
			exit 198    
		}
		local order = substr("`order'",1,1) 
	}

	// format option 
	if "`format'" != "" { 
		capture di `format' 1 
		if _rc { 
			di as err "invalid format " ///
			   as inp "`format' " /// 
			   as err "in " as inp "format()" 
			exit 120 
		} 
	} 	
	else local format "%6.2f" 	
	
	// fillin option 
	if "`fillin'" != "" {
		if `: word count `varlist'' == 1 { 
			// -fillin- makes no sense, but ignore it anyway
			local indata 1
		} 	
		else { 	
			capture confirm new variable _fillin
			if _rc { 
				di as err ///
				"fillin option invalid: _fillin already exists"
				exit 198 
			}
			
			preserve 
			qui keep if `touse' 
			myfillin `varlist' 
			qui replace `touse' = 1 if `touse' == . 
			local indata  "!_fillin"
		} 	
	} 	
	else local indata 1 

	if "`nby'" != "" {
		tokenize `varlist' 
		forval i = 1/`nby' { 
			local bylist "`bylist' ``i''" 
		} 	
	}	
	
	// no weights specified? 
	if "`exp'" == "" local exp 1  

	// some calculations done even if user doesn't want to see results
	// there is some inefficiency in this; on the other hand, there 
	// are reasonable requests such -select(f == 1) show(none)- 
	// that should certainly be allowed 
	
	qui {
		local Varlist : subinstr local varlist " " ",", all 
		bysort `touse' `varlist' : gen byte `tag' = _n == 1 & `touse' 

		by `touse' `varlist' : gen double `freq' = ///
			sum(`exp' * `touse' * `indata')  
		by `touse' `varlist' : replace `freq' = `freq'[_N]

		by `touse' `varlist' : gen double `vfreq' = ///
			sum(`exp' * `touse' * `indata' * !missing(`Varlist'))  
		by `touse' `varlist' : replace `vfreq' = `vfreq'[_N]
		
		by `touse' `bylist' : gen `percent' = sum(`freq' * `tag') 
		by `touse' `bylist' : replace `percent' = `percent'[_N] 
		replace `percent' = cond(`tag', 100 * `freq' / `percent', 0) 

		by `touse' `bylist' : gen `vpercent' = sum(`vfreq' * `tag') 
		by `touse' `bylist' : replace `vpercent' = `vpercent'[_N] 
		replace `vpercent' = cond(`tag', 100 * `vfreq' / `vpercent', 0) 
	
		if "`order'" == "h" {
			tempvar negfreq 
			gen double `negfreq' = - `freq' 
			sort `touse' `bylist' `negfreq' `varlist' 
		} 
		else if "`order'" == "l" { 
			sort `touse' `bylist' `freq' `varlist' 
		} 	
			
		by `touse' `bylist' : gen `Freq' = sum(`freq' * `tag')
		by `touse' `bylist' : gen `rfreq' = `Freq'[_N] - `Freq' 
		by `touse' `bylist' : gen `Percent' = sum(`percent')
		by `touse' `bylist' : gen `Vpercent' = sum(`vpercent')
		gen `rpercent' = 100 - `Percent'
		gen `rvpercent' = 100 - `Vpercent'

		if "`ge'" != "" { 
			replace `rfreq' = `rfreq' + `freq' 
			replace `rpercent' = `rpercent' + `percent'
			replace `rvpercent' = `rvpercent' + `vpercent' 
		}
		if "`lt'" != "" { 
			replace `Freq' = `Freq' - `freq' 
			replace `Percent' = `Percent' - `percent'
			replace `Vpercent' = `Vpercent' - `vpercent' 
		}

		foreach v in `vpercent' `Vpercent' `rvpercent' { 
			replace `v' = . if missing(`Varlist') 
		}

		if `"`showhead'"' != "" { 
			tokenize `"`showhead'"'  
			
			local i = 1 
			foreach v of var `Show' { 
				char `v'[varname] `"``i++''"' 
			}
		} 	
		else { 	
			if "`compress'" == "" { 
				char `freq'[varname]      "Freq."
				char `percent'[varname]   "Percent"
				char `vpercent'[varname]  "% Valid"
			} 
			else { 
				char `freq'[varname]      "#"
				char `percent'[varname]   "%"
				char `vpercent'[varname]  "% V."
			}	
			
			if `nCum' > 1 { 
				if "`lt'" == "" { 
					char `Freq'[varname]      "# <="
					char `Percent'[varname]   "% <="
					char `Vpercent'[varname]  "% V. <="
				}
				else { 
					char `Freq'[varname]      "# <"
					char `Percent'[varname]   "% <"
					char `Vpercent'[varname]  "% V. <"
				}
				
				if "`ge'" == "" { 
					char `rfreq'[varname]     "# >"
					char `rpercent'[varname]  "% >"
					char `rvpercent'[varname] "% V. >"
				}
				else { 
					char `rfreq'[varname]     "# >="
					char `rpercent'[varname]  "% >="
					char `rvpercent'[varname] "% V. >="
				}
			} 
			else { 
				char `Freq'[varname]      "Cum."
				char `Percent'[varname]   "Cum."
				char `Vpercent'[varname]  "Cum."
				char `rfreq'[varname]     "Cum."
				char `rpercent'[varname]  "Cum."
				char `rvpercent'[varname] "Cum."
			}
		} 	

		format `percent' `Percent' `rpercent' ///
			`vpercent' `Vpercent' `rvpercent' `format' 

		if "`select'" != "" {
			if `Selectint' {
				replace `tag' = sum(`tag') * `tag' 
				
				if `select' > 0 { 
					replace `tag' = ///
					`tag' & `tag' <= `select' 
				} 		
				else { 
					su `tag', meanonly 
					replace `tag' = ///
					`tag' & `tag' > (r(max) + `select') 
				} 	
			} 	
			else replace `tag' = `tag' & `Select' `W' 
		} 	
	}

	// what to sum 
	if "`sum'" != "" { 
		if index("`Show'", "`freq'") local Sum "`freq'" 
		if index("`Show'", "`percent'") local Sum "`Sum' `percent'" 
		if index("`Show'", "`vpercent'") local Sum "`Sum' `vpercent'" 
		if "`Sum'" != "" local sum "sum(`Sum')" 
		else local sum 
	} 	

	if "`reverse'" != "" { 
		tempvar obs
		gen long `obs' = -_n  
		sort `obs' 
	} 

	list `varlist' `Show' if `tag', `compress' ///
	labvar(`: word 1 of `varlist'') noobs subvarname `sum' `options' 
end 

* avoid problems if _merge already exists 
* -fillin- version 2.1.2  19dec1998
program myfillin
	version 8
	syntax varlist(min=2)
	tokenize `varlist'
	tempfile FILLIN0 FILLIN1
	tempvar merge  
	preserve
	quietly {
		keep `varlist' 
		save `"`FILLIN0'"', replace
		keep `1'
		bysort `1':  keep if _n == _N
		save `"`FILLIN1'"', replace 
		mac shift 
		while "`1'" != "" { 
			use `"`FILLIN0'"', clear
			keep `1'
			bysort `1': keep if _n == _N
			cross using `"`FILLIN1'"'
			save `"`FILLIN1'"', replace 
			mac shift
		}
		erase `"`FILLIN0'"'		/* to save disk space only */
		sort `varlist'
		save `"`FILLIN1'"', replace 
		restore, preserve
		sort `varlist' 
		merge `varlist' using `"`FILLIN1'"', _merge(`merge') 
		noisily assert `merge' != 1
		gen byte _fillin = `merge' == 2
		drop `merge' 
		sort `varlist'
		restore, not
	}
end

/* 

-nby()- is undocumented for the user, as of 1.1.0, except insofar
as you have found this text somehow.  

The effect of -nby(#)- is as if the first # variables of -varlist-
were moved to be the <byvarlist> of -by <byvarlist>:-.  Percents
and cumulatives are calculated with respect to the combinations of
the first # variables, but those # variables are displayed within
each body of -list- results. 

So the same numerical results will appear for

. bysort foreign: groups rep78

and for 

. groups foreign rep78, nby(1) 

but the display is different, and perhaps preferable for some
tastes and circumstances. 

Why not documented? 

1. Perhaps -by:- itself may be generalised to allow different
displays, in which case this would be less desired. 

2. This is a little nonstandard. 

3. The deliberate effect is to insist that the variables which
define distinct combinations are within -varlist- and -list-ed
first. I haven't tried to code more general possibilities.

4. The -sum- of percents will be 100 * #categories. This is not
surprising given what has been done, but it may not be what a user
wants or expects. 

*/ 

