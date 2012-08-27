{smcl}
{* 9May2012 - Michael Costello}{...}
{cmd: Help for phonemesearch}
{hline}

{title:Phonemesearch}

{title:Syntax}

{p 8 18 2}
{cmd:phonemesearch} {help varlist} 
{cmd:searchvar(}{help varname}{cmd:)}
{cmd:searchstr(}{help str}{cmd:)}

{marker des}
{title:Description}

{pstd}{cmd:phonemesearch} goes through a variable in a database looking for specified strings of letters/symbols, and writing all those observations to a database of the same name.

{marker opt}
{title:Options}


{phang}
{cmd:searchvar(}{help varname}{cmd:)} Which variable the function will search though.

{phang}
{cmd:searchstr(}{help str}{cmd:)} List of the phonemes/graphemes that the function should search for, separated by spaces (see example below)



{hline}
{title:Example}

	{stata cd "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\User\Souhila\Searchable Phoneme Database\"}
	{stata use "Manulex10000-MD-MF_9 Avril 2012_final.dta", clear}
	{stata phonemesearch, searchvar(gpmatch) searchstr(a ba ab)}

	{stata phonemesearch, searchvar(gpmatch) searchstr(a- oi -4@t)}


{hline}
{title:Author}

{pstd}
Michael Costello, RTI International (MCostello@rti.org)
