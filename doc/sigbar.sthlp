{smcl}
{* 26Aug2011 - Alex Sax}{...}
{cmd: help sigbar}
{hline}

{title:Makes a bar graph of significant variables}

{title:Syntax}

{p 8 18 2}
{cmd:sigbar} {help varlist}
[weight] [if] [in]
{cmd:,}[
{cmd:dvar(}str{cmd:)}
{opt cont:rol(varlist)}
{opt nolab:el}
{opt nogra:ph}
{opt g:roup}{cmd:(}{help varname}{cmd:)}
{cmd: lsize(}{it:str}{cmd:)}
{opt leg:endoptions}{cmd:(}{it:str}{cmd:)}
{opt twow:ayoptions}{cmd:(}{it:str}{cmd:)}
{cmd:svy}
]


{title:Description}

{pstd}
{cmd:sigbar} takes a list of possibly significant variables and boils it down to only significant ones.  
Once the list contains only significant variables, {cmd:sigbar} makes them into a bargraph.  {cmd:sigbar}
gives you the option of grouping these variables.


{title:Arguments}

{phang}
{cmd:varlist} includes all the variables that {cmd:sigbar} will consider. If {cmd:dvar()} is not specified,
{cmd:sigbar will assume the dependent variable is the first one in {it:varlist}


{title:Options}
{phang}
{opt cont:rol} adds these variables in to the regrssion and controls for them.  Control results not reported.

{phang}
{opt nolab:el} puts variable names instead of variable labels on the bargraph.

{phang}
{opt nogra:ph} prevents {cmd:sigbar} from outputting a graph and makes {cmd:sigbar} run faster.
	
{phang}
{opt gr:}{cmd:oup(}{it:varname str}{cmd:)} tells {cmd:sigbar} how to group variables.

{phang}
{cmd:lsize(}{it:str}{cmd:)} sets the label size on the bargraph.

{phang}
{opt leg:endoptions}{cmd:(}{it:str}{cmd:)} specifies legend options
		
{phang}		
{opt twow:ayoptions}{cmd:(}{it:str}{cmd:)} allows customizations for two-way graphs

{title:Weights and Variances}

{phang}
{cmd:weight}, unless using svy, should be set to wt_final.

{phang}
{cmd:svy} makes {cmd:sigbar} use the svy: command.



{title:Grouping}

{hline}
{phang}
To group, just use the group option like so:

{phang}
{cmd:group(first_group: var2 var3 var6 | second_group: var1 | third_group: var4 var5)}

{phang}
So denote a new group with the group_name and a colon, then list the vars to be placed
in the group.  The pipe characters (|) are there for readability, and can be omitted. 
One could also use any other combination of punctuation. {cmd:group(first: var1 <<NEXT>> second: var2)}
is also valid.

  
{title:Examples}

{hline}
{pstd}
Read in weighted data.  Look at the time-on-task variables and find out which teacher actions significantly affect
student scores.

{cmd}
	use "Z:\Task 3 EGRA\Final Databases\Rwanda\EGRA EGMA SSME 2011\4. EGRMA SSME (S Te Tk Tm HT SI ECO KCO MCO).dta", clear
	
	sigbar k_orf  k_cor_pcnt*, svy
	sigbar cwpm clspm, dvar(orf) group(group1: cwpm | group2: clspm)
{text}


{title:Returned Results}

{hline}
{phang}
{cmd:sigbar} returns the following:

{phang}
Locals

{cmd:r(sigvars)} a list of significant variables

{cmd:r(coef_list)} a list of corresponding coefficients

{phang}
Matrices

{cmd:r(coefs)} a matrix of coefficients


{title:Author}

{pstd}
Alex Sax, University of Maryland
(asax/contractor@rti.org)


{title:Contact}

{pstd}
Michael Costello, RTI International
(mcostello@rti.org)


{title:Also See}
Help: {help [B] bargraph} {help [R] regress}  {help [S] svy}
