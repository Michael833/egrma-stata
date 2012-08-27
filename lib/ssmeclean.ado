program define ssmeclean
	syntax , [LANGuages(str) Keeplength]

{/*Read in codebook*/
// find number of qs in each section
preserve
capture confirm file `"\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Codebook for EGRA & EGMA.xlsx"'
if !_rc & "`update'"==""{
	import excel using "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Codebook for EGRA & EGMA.xlsx", clear firstrow sheet("SSME - COM")
	quietly: export excel using "C:\Program Files\Stata12\docs\Codebook for EGRA & EGMA.xlsx", sheetreplace firstrow(variables) sheet("SSME - COM")
	import excel using "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Codebook for EGRA & EGMA.xlsx", clear firstrow sheet("SSME - COR")
	quietly: export excel using "C:\Program Files\Stata12\docs\Codebook for EGRA & EGMA.xlsx", sheetreplace firstrow(variables) sheet("SSME - COR")
	import excel using "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Codebook for EGRA & EGMA.xlsx", clear firstrow sheet("SSME - CIN")
	quietly: export excel using "C:\Program Files\Stata12\docs\Codebook for EGRA & EGMA.xlsx", sheetreplace firstrow(variables) sheet("SSME - CIN")
	import excel using "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Codebook for EGRA & EGMA.xlsx", clear firstrow sheet("Labels")
	quietly: export excel using "C:\Program Files\Stata12\docs\Codebook for EGRA & EGMA.xlsx", sheetreplace firstrow(variables) sheet("Labels")
	}

//Save info into matrices
import excel using "C:\Program Files\Stata12\docs\Codebook for EGRA & EGMA.xlsx", clear firstrow sheet("SSME - COM")
mata: com_names = st_sdata(.,st_varindex("comnames"))
mata: com_labs = st_sdata(.,st_varindex("comlabs")) 
mata: com_labnames =  st_sdata(.,st_varindex("comvlab"))
import excel using "C:\Program Files\Stata12\docs\Codebook for EGRA & EGMA.xlsx", clear firstrow sheet("SSME - COR")
mata: cor_names = st_sdata(.,st_varindex("cornames"))
mata: cor_labs = st_sdata(.,st_varindex("corlabs")) 
mata: cor_labnames =  st_sdata(.,st_varindex("corvlab"))
import excel using "C:\Program Files\Stata12\docs\Codebook for EGRA & EGMA.xlsx", clear firstrow sheet("SSME - CIN")
mata: cin_names = st_sdata(.,st_varindex("cinnames"))
mata: cin_labs = st_sdata(.,st_varindex("cinlabs")) 
mata: cin_labnames =  st_sdata(.,st_varindex("cinvlab"))
import excel using "C:\Program Files\Stata12\docs\Codebook for EGRA & EGMA.xlsx", clear firstrow sheet("Labels")
mata: lab_names = st_sdata(.,st_varindex("Label1"))
mata: lab_labs = st_sdata(.,st_varindex("Label2")) 
restore
}

{/*Gen Labels*/
mata: st_local("lablength", strofreal(length(lab_names)))
forvalues i=1/`lablength'{
	mata: st_local("label", lab_labs[`i'])
	mata: st_local("labelName", lab_names[`i'])
	if "`label'" != ""{
		local labelDefine ""
		local labelLength = wordcount("`label'")/2
		forvalues j=1/`labelLength' {
			local k = 2*`j'
			local o = 2*`j' - 1
			local word : word `k' of `label'
			local num : word `o' of `label'
			local word = subinstr("`word'","_"," ",.)
			local labelDefine `"`labelDefine' `num' "`word'""'
		}
	label define `labelName' `labelDefine', replace 
	}
}
}

{/*Set up QC*/
local bad_vals ""
}
{/*Create variables*/
foreach test in "com" "cor" "cin"{
	mata: st_local("testlength", strofreal(length(`test'_names)))
	forvalues i=1/`testlength' {
		mata: st_local("varname", `test'_names[`i'])
		mata: st_local("varlab", `test'_labs[`i'])

		capture confirm variable `lang'`varname'
		if _rc capture confirm variable `lang'`varname'_3
		if !_rc {
			if "`test'" == "cor" || "`test'"=="com" {
				mata: st_local("varvalname", `test'_labnames[`i'])
				//Find lesson length
				local max = 0
				while !_rc {
					local max = `max' + 3
					capture confirm variable `lang'`varname'_`max'
					if _rc local max = `max' - 3
				}
				
				//Label variables
				capture confirm variable `lang'`varname'
				if !_rc {
					//for demographic variables
					label variable `lang'`varname' `"`varlab'"'
					if "`varvalname'"!= "" label values `lang'`varname' `varvalname'
					quietly: codebook `lang'`varname', p
					if "`r(notlabeled)'"!="" local bad_vals = "`bad_vals' `r(notlabeled)'"
				}
				else {
					//for time variables
					forvalues j = 3(3)`max' {
						label variable `lang'`varname'_`j' `"`varlab'"'
						if "`varvalname'"!= "" label values `lang'`varname'_`j' `varvalname'
						quietly: codebook `lang'`varname'_`j', p
						if "`r(notlabeled)'"!="" local bad_vals = "`bad_vals' `r(notlabeled)'"
					}
							
					//Create ToT vars
					capture confirm variable `lang'tot_`varname'
					if !_rc quietly: drop `lang'tot_`varname'
					quietly: egen `lang'tot_`varname' = rowtotal(`lang'`varname'_3-`lang'`varname'_`max')
					quietly: replace `lang'tot_`varname' = `lang'tot_`varname'*3
					label variable `lang'tot_`varname' `"`varlab'"'
					
					//Create PcntToT vars
					capture confirm variable `lessonlength'
					if !_rc quietly: drop `lessonlength'
					tempvar lessonlength
					quietly: egen `lessonlength' = rownonmiss(`lang'`varname'_3-`lang'`varname'_`max')
					if "`keeplength'"!="" {
						capture confirm variable `lang'`test'_length
						if _rc gen `lang'`test'_length = `lessonlength'
						}
					capture confirm variable `lang'pcnttot_`varname'
					if _rc quietly: gen `lang'pcnttot_`varname' = `lang'tot_`varname'/(3*`lessonlength')
					else quietly: replace `lang'pcnttot_`varname' = `lang'tot_`varname'/(3*`lessonlength')
					label variable `lang'pcnttot_`varname' `"`varlab'"'
						
					//Order
					order `lang'tot_`test'*, last
					order `lang'pcnttot_`test'*, last
				}
			}
			else {
				label variable `lang'`varname' `"`varlab'"'
				if "`varvalname'"!= "" label values `lang'`varname' `varvalname'
				quietly: codebook `lang'`varname', p
				if "`r(notlabeled)'"!="" local bad_vals = "`bad_vals' `r(notlabeled)'"
			}
		}
	}
}
/*Find the predominant language in each 9 minute block
   forvalues i = 3(3)`max' /*in blocks of 3*/ {
		local first = `i'
		local iandsix = `i' + 6
		forvalues j=`i'(3)`iandsix' {
			capture confirm variable `variable'_`j'
			if !_rc local third = `j'
		}
	 foreach variable in `test'13 `test'14 `test'15 `test'16 {
		 egen block`i' = rowmedian(`variable'_`first'-`variable'_`third')
		 by class_id: replace block`i' = mode(block`i')
		 label variable block`i' "Predominant language in minutes `i' through `j'"
		 label values block`i' language
	 }
   }*/
}

{/*Sort */


}


{/*QC*/
if "`bad_vals'"!="" di "Possible bad values on variables: `bad_vals'"
}
end
