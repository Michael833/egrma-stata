program define rtiupdate
	quietly ado uninstall rti_egrma
	quietly net install rti_egrma, from("\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\egrma-stata") force replace
	di "     RTI package is now up to date."
end
