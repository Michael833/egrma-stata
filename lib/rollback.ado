
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
	getegrmalocations
	capture confirm file `"`s(test)'/`anything'"'
	if _rc copy `"`s(production)'/`anything'"' `"`s(test)'/`anything'"', replace
	rm `"`s(production)'/`anything'"'
end
