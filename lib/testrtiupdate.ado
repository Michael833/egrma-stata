program define testrtiupdate
	program drop testrtiupdate
	capture: ado uninstall outtable
	quietly: ado uninstall rti_egrma
	net install rti_egrma, from("\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\User\Alex\RTIegrma (test)")
	mata: mata mlib index
	di "     RTI package is now up to date."
end
