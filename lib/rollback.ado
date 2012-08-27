
*****************************************************
* Moves a file backwars from production to test     *
* Just type:                                        *
*   rollback filepath                               *
* Where filepath can be                             *
* 	lib/outtable.ado            - one ado file      *
*	doc/pivottable.sthlp        - one help file	    *
*****************************************************
** DONT USE QUOTES	**								*
*****************************************************

program rollback
	syntax anything

capture confirm file `"Z:\Task 3 EGRA\Final Databases\User\Alex\RTIegrma (test)/`anything'"'
if _rc copy `"Z:\Task 3 EGRA\Final Databases\stata add-ons/`anything'"' `"Z:\Task 3 EGRA\Final Databases\User\Alex\RTIegrma (test)/`anything'"', replace
rm `"Z:\Task 3 EGRA\Final Databases\stata add-ons/`anything'"'

end
