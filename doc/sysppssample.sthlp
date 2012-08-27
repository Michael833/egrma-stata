{smcl}
{* 31Apr2012 - Michael Costello}{...}
{cmd: help sysppssample}
{hline}

{title:Systematic PPS Sampling Program}

{title:Syntax}

{p 8 18 2}
{cmd:sysppssample} 
{it:#} 
{cmd:,} 
{cmd: mos}({it:{help varname}})
{cmd: seed}(integer)
[{opt strata}({it:{help varlist}}) {opt weight:s}(pop / prob) drop]


{title:Options}

{phang} 
{cmd:int} select the number of observations to be drawn from each strata.  {help sysppssample} will select the same number from each strata.

{phang}
{cmd:mos}({help varname}) specifies the variable on which the PPS will be structured.

{phang}
{cmd:seed}(integer) sets the seed number for the random variables within the {help sysppssample}.

{phang}
{cmd:weights}(pop / prob) a variable called weight will be added to the final dataset with either the probability of selection (0 < weight <= 1) or the number of units in the population that the selected observation represents (1 <= weight <= inf.). "pop" will use the stratum sum of the measure of size divided by the observation's measure of size.  "Prob" will use the inverse of "pop".

{phang}
{cmd:drop} will drop observations which were not selected.

{hline}
{title:Example}

	{stata `"use "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\User\Alex\sysppsexample.dta", clear"'}
	sysppssample 5, mos(class_size) seed(92679) strata(treatment district) weights(pop)
	sysppssample 5, mos(class_size) seed(92679) strata(treatment district) weights(pop) drop

{hline}
{title:Author}

{pstd}
Michael Costello, RTI International (MCostello@rti.org)
