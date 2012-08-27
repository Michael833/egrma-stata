{smcl}
{* 31Apr2012 - Michael Costello}{...}
{cmd: Help for tableout}
{hline}

{title:Tableout}

{title:Syntax}

{p 8 18 2}
{cmd:tableout} {help varlist} 
{cmd: using} {help filename} 
{cmd:[ {help weight} ]} 
{cmd:[{opt sampu:nit}}{help (varname)}
{cmd:,}
{cmd:contents}{help (str)}
{cmd:{opt excel:options}}{help (str)}
{cmd:{opt labels ]}}

{marker des}
{title:Description}

{pstd}{cmd:tableout} calculates and displays tables of statistics in Excel. 

{marker opt}
{title:Options}

{phang}
{cmd: {help varlist}} should contain up to three variables in which statistics are to be calculated. These statistics are then exported into Excel.

{phang}
{cmd:using} {help filename} tells tableout where to store its table.

{phang}
{cmd:{opt sampu:nit}}{help (varname)} denotes the smallest unit being tabulated in the table. Example: in a student level database, if the sampuint(school_code) is used then the tables will be a count of the number of schools by {help varlist}.

{phang}
{cmd:contents}{help (str)} what statistics tableout should carry throughout. See {help table}

{phang}
{cmd:{opt excel:options}}{help (str)} check {help export excel}

{phang}
{cmd:{opt labels}}

{hline}
{title:Example}

	{stata use "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Liberia\LTTP2\3. LTTP2 Liberia Baseline - Std.dta", clear}
	{stata table school_code grade female}
	{stata tableout school_code grade female using "test.xlsx", exceloptions(sheetmodify) contents((count) id)}

	{stata use "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Liberia\LTTP2\3. LTTP2 Liberia Baseline - Std.dta", clear}
	{stata table school_code grade female}
	{stata tableout school_code grade female using "test.xlsx", exceloptions(sheetmodify) contents((count) id) labels}


{hline}
{title:Author}

{pstd}
Michael Costello, RTI International (MCostello@rti.org)
