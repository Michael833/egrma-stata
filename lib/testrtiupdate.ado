program define testrtiupdate
	quietly ado uninstall rti_egrma
	quietly net install rti_egrma, from("\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\User\Alex\RTIegrma (test)") replace
	di "     RTI package is now up to date."
end
