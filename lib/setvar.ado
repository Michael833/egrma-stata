program define setvar 
	syntax varname, [VLabelname(str) REName(str) ENCode DECode Label(str) RECode(str) DEstring order(str)]
if "`destring'"!="" capture destring `varlist', replace
if "`encode'"!="" {
	tempvar genned
	encode `varlist', gen(`genned')
	drop `varlist'
	ren `genned' `varlist'
	}
if "`decode'"!="" {
	tempvar genned
	decode `varlist', gen(`genned')
	drop `varlist'
	ren `genned' `varlist'
	}
if "`recode'"!="" recode `varlist' `recode'
if "`vlabelname'"!="" label values `varlist' `vlabelname'
if "`label'"!="" {
  local length: length local label
  if `length'>80 di as text "note: label greater than 80 chars, truncated."
  label variable `varlist' `"`label'"'	
}
if "`rename'"!="" ren `varlist' `rename'
if "`order'"!="" order `varlist', `order'
end
	