{smcl}
{* 14Nov2011 - Alex Sax}{...}
{cmd: help egrmaclean}
{hline}

{title:Automatically standardizes and recodes EGRMA datasets}

{title:Syntax}

{p 8 18 2}
{cmd:egrmaclean} {help varlist}
{cmd:,}
[{opt read:word}{cmd:(}{it:numlist int}{cmd:)} {opt mlev:els}{cmd:(}{help str}{cmd:)} {opt lang}{cmd:(}{help str}{cmd:)}
{opt noup:date} {cmd: print} {cmd: misstime(str)}]

{title:Description}

{pstd}
{cmd: egrmaclean} cleans EGRA and EGMA data according to RTI standards.  
Cleans, labels, does QC checks, and creates summary and super summary variables. 
For information on how egrmaclean computes summary statistics, see the last 
section of this document.  A comprehensive list of features is under development 
but available at {help egrmafeatures}.

{pstd}
{cmd: egrmaclean} automatically pulls demographic and test information from the 
master codebook and stores it locally. If you want to make changes to the way 
that egrmaclean processes tests, do so at:

{cmd:"\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Codebook for EGRA & EGMA.xlsx"}


{title:Arguments}

{phang}
{it:varlist} includes all the variables that {cmd:egrmaclean} will clean.
{cmd:egrmaclean} will leave unfamiliar variables alone, so {it:varlist} 
should almost always be -*- (omit the dashes).


{title:Options}

{phang}
{opt read:word}{cmd:(}{it:numlist int}{cmd:)} recodes reading comprehension
scores to missing if the student did not read enough to answer the
question. 

{phang}
{opt mlev:els}{cmd:(}{it:str}{cmd:)} creates summary variables two distinct levels.
Allows "add" and "sub". So if addition lvl1 ends at question 5 and subtraction at question 7,
specify "mlevels(add 5 sub 7)"

{phang}
{cmd: misstime(str)} if a student should have a time_remain for a section but doesn't, {cmd: egrmaclean} saves that student into a database,
along with the variables that the user specifies in {cmd:misstime(str)}. To access, use {cmd: `r(misstime)'}

{phang}
{cmd: print} Shows how many observations are being recoded to missing using the oral_read_attempted -> read_comp correction. 

{phang}
{opt lang}{cmd:(}{it:str}{cmd:)} allows egrmaclean to handle databasts with multiple languages.
Feed {cmd: languages()} the prefix associated with each language. Ex: {cmd: languages(k_)} or {cmd: languages(r_)}

{phang}
{opt noup:date} Not recommended. Allows the user to save time and not copy the codebook to the C:/ drive. Only
use this option if you are {it: sure} that you have the latest copy.

{phang}
{cmd: write} is a developer's command and outputs exactly what egrmaclean is doing at a given time. 
Not recommended.

{title:Examples}

{hline}
{phang}
Read in data, then clean. Create two levels for math variables.

	{cmd:use "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\User\Alex\RTIdocs\mlevels example.dta", clear}

	{stata egrmaclean *, mlev(add 5 sub 5) :egrmaclean *, mlev(add 5 sub 5)}

	
	
{phang}
Use the readwords option to correct. The vocab section doesn't have item-level variables, but {cmd:egrmaclean} handles it.

	{cmd:use "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\DRC\Baseline\3. DRC Standardized and Weighted EGRA & EGMA.dta", clear}
	
	{stata egrmaclean *, read(8 19 24 28 50):egrmaclean *, read(8 19 24 28 50)}

	
	
{phang}
Clean multiple languages.  Tell egrmaclean which {cmd:lang()} you want to clean and do english last, so that
the demographic variables are at the top of the dataset.  This example uses {cmd:noupdate} because the local codebook was updated in 
the first {cmd:egrmaclean}.

	{cmd:use "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Rwanda\EGRA EGMA SSME 2011\3. Rwanda Weighted Clean Standard -Wide Form.dta", clear}
	
	{stata egrmaclean *, read(12 40 50) lang(k_):egrmaclean *, read(12 40 50) lang(k_)}
	
	{stata egrmaclean *, read(12 19 25) noup:egrmaclean *, read(12 19 25) noup}


	
{phang}
Finf missing times.

	{cmd:use "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Rwanda\EGRA EGMA SSME 2011\3. Rwanda Weighted Clean Standard -Wide Form.dta", clear}
	
	
	{stata egrmaclean *, read(12 19 25) misstime(grade) noup:egrmaclean *, read(12 19 25) misstime(grade) noup}

{title:Calculations}

{hline} 
{pstd}
{cmd:Here is how each of the summary variables are calculated}

{phang} 
{cmd:General Score Sections}

quietly: egen `section'_score=rowtotal(`section'1-`section'`length'), missing 


{phang} 
{cmd:Dictation/Invented Dictation Score Sections}

quietly: egen `section'_score1 = anycount(`section'1-`section'`length'), v(1)

quietly: egen `section'_score2 = anycount(`section'1-`section'`length'), v(2)

quietly: gen `section'_score=`section'_score1+(`section'_score2)/2

drop `section'_score1 `section'_score2

quietly: recode `section'_score (0=.) if missing(`section'1-`section'`length') 


{phang}
{cmd:Score Pcnt}

quietly: gen `section'_score_pcnt=`section'_score/`length'

quietly: summarize `section'_score_pcnt


{phang}
{cmd:Attempted}

quietly: egen `section'_attempted=rownonmiss(`section'1-`section'`length') 


{phang}
{cmd:Attempted Pcnt}

quietly: gen `section'_attempted_pcnt=`section'_score/`section'_attempted 


{phang}
{cmd:Zero Score}

quietly: gen `section'_score_zero= (`section'_score==0) if `section'_score<.


{phang} 
{cmd:Read Comp Score Pcnt 80}

quietly: gen read_comp_score_pcnt80= (read_comp_score_pcnt>=.8) if read_comp_score_pcnt<.

quietly: recode read_comp_score_pcnt80 (.=0) if oral_read1 !=.  (This is done when item level oral_read variables exist)

quietly: recode read_comp_score_pcnt80 (.=0)  (This is done when item level oral_read variables do not exist)

{phang} 
{cmd:Read Comp Attempted Pcnt 80}

quietly: gen read_comp_attempted_pcnt80= (read_comp_attempted_pcnt>=.8) if read_comp_attempted_pcnt<.

{phang} 
{cmd:Fluency (Timed Section "Per Minute" Variables)}

quietly: gen `perMinuteVariable'=`corresponding'_score/(1-(`corresponding'_time_remain/60))


{hline}

{title:Returned results}

{phang}
{cmd:r(misstime) a local that stores the command to open the dataset containing the results of misstime


{hline

{title:Authors}

{pstd}
Alex Sax, University of Maryland (asax/contractor@rti.org)

Michael Costello, RTI International (MCostello@rti.org)

{title:Also See}

{pstd}
Help: {help svyset}, {help rti}, {help egrmafeatures}
