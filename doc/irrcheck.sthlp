{smcl}
{* 29Feb2012 - Alex Sax - HAPPY LEAP DAY}{...} 
{cmd: help irrcheck}
{hline}

{title:Grades admins for accuracy}

{title:Syntax}

{p 8 18 2}
{cmd:irrcheck} {cmd:,[exclude(}{help varlist}{cmd:)} {opt sep:arately}{cmd:(}{help varlist}{cmd:) {opt gen:erate}{cmd:(str)}

{title:Description}
{pstd}
{cmd:irrcheck} quickly determines what proportion of marks each administrator correctly made, using the first
observation as a baseline.

{title:Options}
{pstd}
{cmd:exclude()} removes these variables from consideration. Include things like 'admin name' or 'admin id', because 
of course these things will differ from the control admin.

{pstd}
{cmd:separately()} creates a separate pcnt_correct of only the variables specified. This allows the user to isolate
specific important variables.

{pstd}
{cmd:generate()} creates specifies what the return variables are to be named. One will be the string specified and the other
will be sep_<<String Specified>>. Default="prop_correct"

{title:Remarks}
{pstd}
To visually see how each assessor is doing, try this code:

{pstd}
graph bar (asis) pcnt_correct, by(admin_id)


{title:Author/Contact}
{pstd}
Alex Sax: asax/contractor@rti.org
Michael Costello: mcostello@rti.org
