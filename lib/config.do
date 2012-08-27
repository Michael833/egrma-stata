**********************
* Configuration file *
*   for egranalysis  *
**********************

** Categorizing dependent variables
local fluency 		clpm cnonwpm orf
local zeroscores 	*_score_zero
local scores 		*_score

** Set demographics
loc geographics 		"state region county division district zone"
loc subpops 			"grade female urban region"
loc	overs 				"treat_phase"
loc treatment 			"treatment"
loc schoolIdentifier 	"school"

** Breakdowns for contingency tables
local double_subpops `""grade female"  "female grade"   "grade region"    "region female""'

** Frequency Tables
loc genTableBySchoolFor 	`""grade female" "grade""'
loc genTableByStudentFor 	"school grade" "grade female"

** Output
local location 			"C:\Documents and Settings\asax\Desktop"
local outputvars 		mean sd count se ci N tstats effects
local svytype 			svy iid
local outtableExcelOptions 		"sheet(\`subtests' \`set') sheetmodify cell(A1) first(var)"
local tableoutExcelOptions 		"sheet(Specs) sheetmodify"
