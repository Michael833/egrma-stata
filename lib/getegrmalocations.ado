********************************************
* Locations of production and test folders *
* As well as ancilliary files              *
********************************************

program getegrmalocations, sclass
	local 			production 				"\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\egrma-stata\"
	local 			on_access_rti_drive 	"`production'assets\on_access_rti_drive.do"	
	sreturn local 	test 					"\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\User\Alex\RTIegrma (test)\"
	sreturn local 	production 				"`production'"
	sreturn local 	label_file 				"\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\egrma-stata\assets\Labels for EGRA & EGMA.do"
	sreturn local 	codebook 				"\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Codebook for EGRA & EGMA.xlsx"
	sreturn local 	config 					"\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\egrma-stata\assets\config.do"
	capture include "`on_access_rti_drive'"
end
