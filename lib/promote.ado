
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
	
copy `"Z:\Task 3 EGRA\Final Databases\User\Alex\RTIegrma (test)/`anything'"' `"Z:\Task 3 EGRA\Final Databases\egrma-stata/`anything'"', replace

end
