program define qartiupdate
	program drop qartiupdate
	quietly: ado uninstall rti_egrma
	net install rti_egrma, from("\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\User\Alex\RTIegrma (QA)")
	mata: mata mlib index
	di "     RTI package is now up to date."
end