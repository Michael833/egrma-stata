* Database Searching Function
* To find phonemems in a database
* Michael Costello, StatEpi, RTI International
* Alex Sax, IDG, RTI International
* May 9, 2012

/* Example:
cd "Z:\Task 3 EGRA\Final Databases\User\Souhila\Searchable Phoneme Database\"
use "Manulex10000-MD-MF_9 Avril 2012_final.dta", clear
compress _all
local searchvar gpmatch
local searchstr "a- b 4t-"
*/
program define phonemesearch
	syntax, searchvar(varname) searchstr(str)
	version 12
preserve 
local ppipe ""
local gpipe ""

// Modify the user input into a useable regexp
foreach query in `searchstr' {
  if substr("`query'",1,1)=="-" {
    local graphemes = "`graphemes'`gpipe'" + substr("`query'",2,.) + ""
	local gpipe "|"
  }
  else if substr("`query'",-1,1)=="-" {
    local length: length local query
    local phonemes = "`phonemes'`ppipe'" + substr("`query'",1,`length'-1) + ""
	local ppipe "|"
  }
  else {
   local graphemes = "`graphemes'`gpipe'`query'"
   local phonemes = "`phonemes'`ppipe'`query'"
   local gpipe "|"
   local ppipe "|"
 }
}

display "^(([\.\-\(](`phonemes')\-[^\.\-\)]+)|([\.\-\(][^\.\-\(]+\-(`graphemes')))+\)*$"
keep if regexm(`searchvar',"^(([\.\-\(](`phonemes')\-[^\.\-\)]+)|([\.\-\(][^\.\-\(]+\-(`graphemes')))+\)*$")
*^(([\.\-\(]((e))\-[a-zA-Z]+)|([\.\-\(][a-zA-Z]+\-((R)|(m)|(O))))+\)$
*list `searchvar'
quietly save "`searchstr'.dta", replace
display "File `searchstr'.dta saved in directory `c(pwd)'"
restore

end
