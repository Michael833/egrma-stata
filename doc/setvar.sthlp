{smcl}
{* 27Feb2012 - Alex Sax}{...}
{cmd: help setvar}
{hline}

{title:Sets almost all of the information about one variable}

{title:Syntax}

{p 8 18 2}
{cmd:setvar} {help varname}
{cmd:,}
[{opt enc:ode} {opt dec:ode} {opt DE:string}
{opt rec:ode}{cmd:(}{help str}{cmd:)}
{opt ren:ame}{cmd:(}{it:str}{cmd:)} 
{opt l:abel}{cmd:(}{help str}{cmd:)} 
{opt vl:abelname}{cmd:(}{help str}{cmd:)}]

{title:Description}
{pstd}
{cmd:ssmeclean} is just a nice interface to manipulate a single variable in several ways at once. 



{title:Allowable manipulations}

{hline}

{help encode}: for string -> numeric with value labels

{help decode}: for numeric -> string

{help destring}: string -> numeric and nonnumeric values become missing

{help rename}: to change the name

{help label variable}: label the variable

{help help label values}: apply an already defined value label

{hline}

{title:Examples}

setvar KG, rename(exit_interview2) label("Has a radio at home") recode((9=.) (8=.)) vlabelname(yesno)
