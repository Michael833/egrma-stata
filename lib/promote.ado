
*****************************************************
* Moves a file from test to production              *
* Just type:                                        *
*   promote filepath                                *
* Where filepath can be                             *
* 	lib/outtable.ado            - one ado file      *
*	doc/pivottable.sthlp        - one help file	    *
*****************************************************
** DONT USE QUOTES	**								*
*****************************************************

program promote
	syntax anything
	getegrmalocations
	copy `"`s(test)'/`anything'"' `"`s(production)'/`anything'"', replace
end
