{smcl}
{* 14Nov2011 - Alex Sax}{...}
{cmd: help ssmeclean}
{hline}

{title:Automatically standardizes and recodes SSME datasets}

{title:Syntax}

{p 8 18 2}
{cmd:ssmeclean} 
{cmd:,}
[{opt lang:uages}{cmd:(}{help str}{cmd:)}
{opt noup:date}]

{title:Description}

{pstd}
{cmd: ssmeclean} cleans SSME data according to RTI standards.  
Cleans, labels, and does QC checks. {cmd:ssmeclean} takes on argument but allows 2 options, shown below.

{pstd}
{cmd: ssmeclean} automatically pulls demographic and test information from the 
master codebook and stores it locally. If you want to make changes to the way 
that egrmaclean processes tests, do so at:

{cmd:"\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Codebook for EGRA & EGMA.xlsx"}


{title:Options}

{phang}
{opt lang:guages}{cmd:(}{it:str}{cmd:)} allows egrmaclean to handle databasts with multiple languages.
Feed {cmd: languages()} the prefix associated with each language. Ex: {cmd: languages(k_)} or {cmd: languages(r_)}

{phang}
{opt noup:date} Not recommended. Allows the user to save time and not copy the codebook to the C:/ drive. Only
use this option if you are {it: sure} that you have the latest copy.


{title:Authors}

{pstd}
Alex Sax, University of Maryland (asax/contractor@rti.org)

Michael Costello, RTI International (MCostello@rti.org)

{title:Also See}
