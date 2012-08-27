program define rtiupdate
	capture program drop rtiupdate
	capture ado uninstall rti_egrma
	capture net install rti_egrma, from("\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\stata add-ons")
	di "     RTI package is now up to date."
end
