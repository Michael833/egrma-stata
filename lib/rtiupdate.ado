program define rtiupdate
syntax , [test]
	getegrmalocations
	quietly ado uninstall rti_egrma
	if "`test'"=="test" local repo "`s(test)'"
	else local repo "`s(production)'"
	quietly net install rti_egrma, from("`repo'") replace
	di "     RTI package is now up to date."
end
