cd "C:\Documents and Settings\asax\Desktop"
clear
set obs 24
gen goldstandard = 0
replace goldstandard = 1 in 3
forvalues i=1/10 {	
	gen letter_`i' = .
}
forvalues i=1/8 {
	replace letter_`i' = 0 in 1
	replace letter_`i' = 1 in 2
	replace letter_`i' = 1 in 3
	replace letter_`i' = round(runiform()) in 4
}
forvalues i = 5/8 {
	replace letter_`i' = 0 in 3
}

//gen letter_time_remain = .
//replace letter_time_remain = round(runiform()*60)
//replace letter_time_remain = letter_time_remain[3] + 1 in 2
gen  admin_name = _n
tostring admin_name, replace
replace admin_name = ":)" in 1
replace admin_name = ":(" in 2
replace admin_name =  "*" in 3
replace admin_name = ":|" in 4

irrcheck
gsort -PNA
list admin_name PNA
