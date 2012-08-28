program define testrtiupdate
	getegrmalocations
	quietly ado uninstall rti_egrma
	quietly net install rti_egrma, from("`s(test)'") replace
	di "     RTI package is now up to date."
end
