* Auto Cleaning File
* Alex Sax & Michael Costello
* RTI International
* May 2012

/* Notes:
		If you make a change in this file, you must reflect that change in the table of contents,
		egrmaclean.sthlp, and egrmafeatures.sthlp files
*/

program define egrmaclean, rclass
  syntax varlist , [READwords(numlist) UNTREADwords(numlist) lang(str) MLEVels(str) print noUPdate write misstime(str) EQuate(str)]
  version 12
 
 
  global codebook_handle "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Codebook for EGRA & EGMA.xlsx"
  global label_file_handle "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Labels for EGRA & EGMA.do"
  global local_codebook_handle "`c(sysdir_plus)'Codebook for EGRA & EGMA.xlsx"
  global local_label_file_handle "`c(sysdir_plus)'Labels for EGRA & EGMA.do"
  global lang "`lang'"
  global errors_in_item_levels ""
  local varabbrev = "`c(varabbrev)'"
   
  tempvar pholder misstime_sections 
  global placeholder "`pholder'"
  global misstime_sections "`misstime_sections'"
  capture gen ${placeholder} = .   
  quietly: gen str244 $misstime_sections = ""

{/*Precleaning*/ 
set varabbrev on

//Set up matrices and precleaning based on user input
   local input_local = subinstr("`readwords'",  " "  ,  ",",  .)
   matrix input readWordNeeded = (`input_local')
   local input_local = subinstr("`untreadwords'",  " "  ,  ",",  .)
   matrix input unt_readWordNeeded = (`input_local')
   
   
*************************************************************************
* egrmaclean uses two methods of reading in configuration data			*
* 	 Since egrmaclean should work offline, it also stores a local 		*
* 	 copy of each of these methods in the sysdir_plus directory			*
*																		*
*  The first method, the codebook, is a .xlsx file where each sheet		*
* 	 defines attributes for a group of variables. egrmaclean reads in	*
* 	 these values and keeps them accessible in a mata matrix			*
*																		*
*  The second method is very simple. egrmaclean quietly runs a do 		*
*	  file that defines all the labels egrmaclean uses.           	 	*
*************************************************************************  	

// If we have access to the RTI server then pull the codebook into a bunch of mata matrices
// and store them in the file denoted by $local_codebook_handle
// Otherwise, just use the local version
  capture confirm file "$codebook_handle"
  if !_rc & "`update'"==""{
    preserve
	import excel using "$codebook_handle", clear firstrow sheet("Demographics")
    create_matrix_from_data demographicInfo
	import excel using "$codebook_handle", clear firstrow sheet("Test Sections")
    create_matrix_from_data testSectionInfo
    import excel using "$codebook_handle", clear firstrow sheet("Super Summary")
    create_matrix_from_data superSummaryInfo
    import excel using "$codebook_handle", clear firstrow sheet("Commonly Misnamed Variables")
    create_matrix_from_data renpfixInfo
	
	quietly copy "$label_file_handle" "$local_label_file_handle", replace
	
	save_matrices demographicInfo testSectionInfo superSummaryInfo renpfixInfo using "$local_codebook_handle"
    display "Updated local codebook"
	restore
  }
  else get_matrices demographicInfo testSectionInfo superSummaryInfo renpfixInfo using "$local_codebook_handle"

//Define the labels
  quietly include "$local_label_file_handle"
  
//renpfix stuff
  renpfix_from renpfixInfo

//Order to make everything all nice for egrmaclean's many rowtotals
  order ${placeholder}, first


//equating 
if "`equate'"!="" make_equate `equate'
			
//Information about how the test
  mata: st_global("possiblesections", strofreal(rows(testSectionInfo)))
  mata: st_global("super_summary_sections", strofreal(rows(superSummaryInfo)))
  mata: st_global("demographic_sections", strofreal(rows(demographicInfo)))

//Split maths
  if "`mlevels'"!="" split_maths `mlevels'
  
  if "`lang'" != "" di as text "Language prefix set to " as result "`lang'" 
  display in smcl "{c TLC}{hline 32}{c TT}{hline 7}{c TT}{hline 8}{c TT}{hline 50}{c TRC}"
  display in smcl "{c |}         Section Name           {c |} Items {c |} Scaled {c |}                   Problems{col 102}{c |}"
  display in smcl "{c LT}{hline 32}{c +}{hline 7}{c +}{hline 8}{c +}{hline 50}{c RT}"
}
{/*Concepts of Text*/
  capture setvar ${lang}cot_location, recode((9=.) (99=.) (8=0) (3=0) (-1=.) (11=1)) label(The child puts finger on the top left letter?) vlabelname(yesno) order(b(${placeholder}))
  capture setvar ${lang}cot_direction, recode((9=.) (99=.) (8=0) (3=0) (-1=.) (11=1)) label(The child moves finger from left to right?) vlabelname(yesno) order(b(${placeholder}))
  capture setvar ${lang}cot_next_line, recode((9=.) (99=.) (8=0) (3=0) (-1=.) (11=1)) label(The child moves finger to second line after finishing the first) vlabelname(yesno) order(b(${placeholder}))
}
/*Section loop*/ forvalues i=2/$possiblesections {


* Set up macros that keep track of important values for the section  
  create_obs_global section sectionName sectionValueLabelName using testSectionInfo, obs(`i')
  local length = 1
  local label_issues_in_section ""
  
* Item level loop  
  while 1 {
  //Rename and set infomation
    capture: ren ${lang}${section}_`length' ${lang}${section}`length'
    capture: ren ${lang}${section}0`length' ${lang}${section}`length'
    capture: setvar ${lang}${section}`length', vlabelname(${sectionValueLabelName}) label(${lang} $sectionName `length') recode((9=.) (99=.) (999=.) (8=0) (3=0) (-1=.) (11=1)) order(b(${placeholder})) destring
    if _rc continue, break
	
    if "${section}"=="read_comp" | "${section}"=="unt_read_comp" reading_item_level_exception ${section} `length' `print'
    else if "${section}"=="addlvl2" | "${section}"=="sublvl2" | "${section}"=="multlvl2" | "${section}"=="divlvl2" math_item_level_exception ${section} `length'
	
    quietly: codebook ${lang}${section}`length', problems
    if "`r(notlabeled)'"!="" local label_issues_in_section "`label_issues_in_section' (`length')" 
    local ++length
  }
  local --length  // Decrement because we exit the loop only after we go one too far
  

/*Summary Variables -- Only generates a new summary if there are item level vars to gen it from*/
  generate_score ${section} `length' ${sectionValueLabelName} "${sectionName}"
  //generate_max_score ${section} `length' "${sectionName}"
  equate_score ${section} `equate'
  set_time_remain ${section} `misstime'  "${sectionName}"
  generate_score_pcnt ${section} `length'  "${sectionName}"
  generate_zero_score ${section}  "${sectionName}"
  set_auto_stop ${section}  "${sectionName}"
  generate_attempted ${section} `length'  "${sectionName}"
  generate_attempted_pcnt ${section}  "${sectionName}"

/*QC Checks*/
  section_qc_check ${section} `length' `r(equate_val)'
  if "`label_issues_in_section'"!="" global errors_in_item_levels "${errors_in_item_levels} | ${lang}${section}`label_issues_in_section'"
}
{/*Super Summary Variables*/
order ${placeholder}
display in green "{c BLC}{hline 32}{c BT}{hline 7}{c BT}{hline 8}{c BT}{hline 50}{c BRC}" _n
display as result "Starting Super Summary Variables"

forvalues i=1/$super_summary_sections {
  create_obs_global superSummaryName superSummaryVarLabel qcLimit superSummarySection using superSummaryInfo, obs(`i')

  //Depending on the section, we calculate the summary variable in different ways
  if "$superSummarySection" == "read_comp" | "$superSummarySection" == "unt_read_comp" create_read_comp $superSummarySection $superSummaryName $qcLimit
  else create_general_summary $superSummarySection $superSummaryName $qcLimit 
}
}
{/*Demographics*/
order ${placeholder}
di as result _n "Starting Demographics"
forvalues i = 1/${demographic_sections} {
  create_obs_global demographic_name demographic_vlabelname demographic_vlabel demographic_label demographic_necessary  demographic_message using demographicInfo, obs(`i')
  capture setvar ${lang}${demographic_name}, vlabelname(${demographic_vlabelname}) label(${demographic_label}) order(b(${placeholder}))
  
  //QC Checks
  if _rc & "${demographic_necessary}"!="" di in red "${lang}${demographic_name} not found: ${demographic_message}" //necessary error
  if "${demographic_name}"=="id" { //id error
	capture isid id
	if _rc display in red "id does not uniquely identify observations"
  }
  if "${demographic_vlabelname}"!="" & !_rc { //unlabeled values error
	quietly: codebook ${lang}${demographic_name}, p
	if "`r(notlabeled)'" != "" global errors_in_item_levels = "${lang}${demographic_name} | ${errors_in_item_levels}"
  }
}
}
{/*Cleanup*/
if "`mlevels'"!="" combine_maths "`mlevels'"
if "$errors_in_item_levels" != "" display in red "Check sections for nonboolean values $errors_in_item_levels"
if "`misstime'"!="" {
  preserve
  quietly: keep if ${misstime_sections} != ""
  quietly: keep `misstime' $misstime_sections
  quietly: sort ${misstime_sections} `misstime'
  ren ${misstime_sections} missing_sections
  quietly: compress
  quietly: save "`c(tmpdir)'misstime.dta", replace
  list *, noo clean
  return local misstime `"use "`c(tmpdir)'misstime.dta", clear"'
  restore
}
set varabbrev `varabbrev'
}
end 

{/*Precleaning FUNCTIONS*/
program define create_matrix_from_data 
// Brings the codebook from a dataset in as a matrix, which can be accessed as part of the cleaning.
  args matrix_name
  mata: `matrix_name' = create_matrix_from_data()
end

program define save_matrices
  syntax namelist using/
  mata: handle = fopen("`using'", "rw");
  foreach new_matrix in `namelist' {
    mata: fputmatrix(handle, `new_matrix')
  }
  mata: fclose(handle)
end

program define get_matrices 
//Used for accessing each matrix when there is not access to the RTI server.
  syntax namelist using/
  mata: handle = fopen("`using'", "r");
  foreach new_matrix in `namelist' {
    mata: `new_matrix' = fgetmatrix(handle)
  }
  mata: fclose(handle)
end

program define make_labels_from 
  args label_matrix
//Generate labels from the matrix.  The name is in the first column and the definition lies in the second
//In the definition are key-value pairs. For female:   KEY  VALUE 
//                                                      0   Male
//                                                      1   Female  
  mata: st_local("labsections", strofreal(rows(`label_matrix')))
  forvalues i=1/`labsections'{
	mata: st_local("label", `label_matrix'[`i',2])
	mata: st_local("labelName", `label_matrix'[`i',1])
	if "`label'" != ""{
	  local labelLength: word count `label'
	  forvalues key=1(2)`labelLength' {
		local value = `key' +  1
		local word : word `value' of `label'
		local num : word `key' of `label'
		local word = subinstr("`word'","_"," ",.)
		local labelDefine `"`labelDefine' `num' "`word'""'
	  }
	  label define `labelName' `labelDefine', replace 
	}
  }
end

program define renpfix_from 
  args renpfix_matrix
  mata: st_local("length", strofreal(rows(`renpfix_matrix')))
  forvalues renpfixNum = 1/`length' {
	mata: st_local("currentError", `renpfix_matrix'[`renpfixNum',1])
	mata: st_local("currentFix", `renpfix_matrix'[`renpfixNum',2])
	capture: renpfix ${lang}`currentError' ${lang}`currentFix'
  }
end

program define create_obs_global 
  syntax namelist using/, obs(int)
  local i = 1
  foreach word in `namelist' {
    mata: st_global("`word'", `using'[`obs',`i'])
    local ++i
  }
end

program define split_maths
  syntax anything
  **Determine which section, and how many questions in each level.
  local mLevelsWords: word count `anything'
  forvalues value=`mLevelsWords'(-2)1 {
	local key = `value' -  1
	local cutoff : word `value' of `anything'
	local ++cutoff
	local section : word `key' of `anything'
	capture ren ${lang}`section'*# ${lang}`section'lvl1*#
	// capture di "Works every time ;)"
	while !_rc {
	  capture: ren ${lang}`section'lvl1_`cutoff' ${lang}`section'lvl1`cutoff'
      capture: ren ${lang}`section'lvl10`cutoff' ${lang}`section'lvl1`cutoff'
      capture: ren ${lang}`section'lvl1`cutoff' ${lang}`section'lvl2`cutoff'
	  local ++cutoff
	}
	capture ren ${lang}`section'lvl2# ${lang}`section'lvl2#, renumber
	capture ren *lvl1lvl#* *lvl#*
  }
end
 
program define make_equate 
  syntax anything
  local equate_length: word count `anything'
  mata: equateInfo = ("","")
  forvalues i=1(2)`equate_length'{
	local j = `i' + 1 
	local secname: word `i' of `anything'
	local val: word `j' of `anything'
	mata: equateInfo = (st_local("secname"), st_local("val")\equateInfo)
  }
  mata: st_select(equateInfo, uniqrows(equateInfo),(1,1))
end
}

{/*Item-level FUNCTIONS*/
program define reading_item_level_exception
  args section item print
// Force irem level to missing if the kid did not read far enough  
  if "`section'"=="unt_read_comp" local unt "unt_"
  if "`print'"=="" local shh "quietly"
  capture confirm variable ${lang}`unt'oral_read_attempted
  if !_rc `shh' replace ${lang}`section'`item'=. if ${lang}`unt'oral_read_attempted < `unt'readWordNeeded[1,`item'] & `unt'readWordNeeded[1,`item'] != .   
  order ${lang}`section'`item', b(${placeholder})
end

program define math_item_level_exception
  args section item 
  if "`section'"=="addlvl2" local sec "add"
  else if "`section'"=="sublvl2" local sec "sub"
  else if "`section'"=="multlvl2" local sec "mult"
  else if "`section'"=="divlvl2" local sec "div"
  capture replace ${lang}`section'`item'=. if ${lang}`sec'lvl1_attempted != 0 & ${lang}`sec'lvl1_score == 0   
end
}

{/*Summary FUNCTIONS*/
program generate_score 
  args section length sectionValueLabelName sectionName
// Creates a score variable if one does not already exist.
//Setting up a prefix in case the section is untimed.  This allows us to use one set of code later, rather than two.
  if "`section'"=="unt_read_comp" local unt "unt_"
  else if "`section'"=="sublvl2" local sec "sub"
  else if "`section'"=="addlvl2" local sec "add"
  
  if "`length'"!="0" {
    capture: drop ${lang}`section'_score
    quietly: egen ${lang}`section'_score = anycount(${lang}`section'1-${lang}`section'`length'), v(1)
    if "${sectionValueLabelName}"=="compdict" {
      tempvar score2
      quietly: egen `score2' = anycount(${lang}`section'1-${lang}`section'`length'), v(2)
      quietly: replace ${lang}`section'_score = ${lang}`section'_score + `score2'/2
    }
   
   ** If the section is missing, this should take the 0's returned by -anycount- and change them to missing.
	tempvar nonmissing
	quietly: egen `nonmissing' = rownonmiss(${lang}`section'1-${lang}`section'`length')
    quietly: replace ${lang}`section'_score = . if `nonmissing' == 0
  }
  capture {
    setvar ${lang}`section'_score, label(Total correct ${lang}`sectionName' questions.) order(b(${placeholder})) destring
   
   **Reading and maths exception
	if ("`section'"=="read_comp" | "`section'"=="unt_read_comp") recode ${lang}`section'_score .=0 if (${lang}`unt'oral_read_attempted < `unt'readWordNeeded[1,1]) | (${lang}`unt'oral_read_attempted >= `unt'readWordNeeded[1,1] & ${lang}`unt'oral_read_score == 0)
    if ("`section'"=="addlvl2" | "`section'"=="sublvl2") recode ${lang}`section'_score .=0 if (${lang}`sec'lvl1_attempted > 0 & ${lang}`sec'lvl1_attempted < . & ${lang}`sec'lvl1_score==0) 
  }
end

program generate_max_score
  args section length sectionName
  if "`length'"!="0" {
    capture drop ${lang}`section'_max_score
	gen ${lang}`section'_max_score = `length'
  }
  capture setvar ${lang}`section'_max_score, label(Total ${lang}`sectionName' q's.  Valid iff each test cleaned individually!) order(b(${placeholder})) destring
end  
 
program equate_score, rclass
  args section equate
  if "`equate'"!= "" mata: for(i=1; i<=rows(equateInfo); i++) if(st_local("section")==equateInfo[i,1]) st_local("equate_val", equateInfo[i,2]);;
  if "`equate_val'"!="" quietly: replace ${lang}`section'_score = ${lang}`section'_score*`equate_val'
  return local equate_val "`equate_val'"
end



program set_time_remain 
  args section misstime sectionName
  capture destring ${lang}`section'_time_remain, replace
  capture confirm variable ${lang}`section'_time_remain
  if !_rc quietly: replace ${misstime_sections} = "`section', ${misstime_sections}" if ${lang}`section'_score!=. & ${lang}`section'_time_remain ==.
  capture setvar ${lang}`section'_time_remain, label(Time remaining when finished answering ${lang}`sectionName' questions?) order(b(${placeholder})) destring	
end



program generate_attempted 
  args section length sectionName
  if "`section'"=="unt_read_comp" local unt "unt_"
  if "`length'"!="0" {
    capture drop ${lang}`section'_attempted
    quietly: egen ${lang}`section'_attempted=rownonmiss(${lang}`section'1-${lang}`section'`length') if ${lang}`section'_score!=.
  }
  capture {
    setvar ${lang}`section'_attempted, label(Number of ${lang}`sectionName' questions attempted.) order(b(${placeholder})) destring	
	
	*This is for when, in reading, the assessor for some reason doesn't ask the child the RC question even though they should have asked it.
    if !("`section'"=="read_comp" | "`section'"=="unt_read_comp") quietly: recode ${lang}`section'_attempted (0=.) if ${lang}`section'_score==.
    else quietly: recode ${lang}`section'_attempted (0=.) if ${lang}`unt'oral_read_score==. | (${lang}`unt'oral_read_attempted >= `unt'readWordNeeded[1,1] & ${lang}`unt'oral_read_score > 0)
  }
end



program generate_score_pcnt
  args section length sectionName
  //If item levels exist, recalculate
  if "`length'"!="0"{
    capture: drop ${lang}`section'_score_pcnt
    quietly: gen ${lang}`section'_score_pcnt=${lang}`section'_score/`length'   
  }
  capture setvar ${lang}`section'_score_pcnt, label(Percentage of ${lang}`sectionName' questions correct.) order(b(${placeholder}))	destring 
end



program generate_zero_score
  args section sectionName
  capture {
    capture drop ${lang}`section'_score_zero
    quietly: gen ${lang}`section'_score_zero= (${lang}`section'_score==0) if ${lang}`section'_score<.
	setvar ${lang}`section'_score_zero, vlabelname(zeroscores) label(Student scored zero on ${lang}`sectionName' section.) order(b(${placeholder})) destring
  }
end



program generate_attempted_pcnt
  args section length sectionName
  if "`length'"!="0" {
    capture: drop ${lang}`section'_attempted_pcnt
	capture: gen ${lang}`section'_attempted_pcnt=${lang}`section'_score/${lang}`section'_attempted
  }
  capture {    
  	setvar ${lang}`section'_attempted_pcnt, label(Percentage of attempted ${lang}`sectionName' questions correct.) order(b(${placeholder})) destring
    quietly: recode ${lang}`section'_attempted_pcnt (.=0) if ${lang}`section'_score==0 //& (${lang}oral_read_attempted < readWordNeeded[1,1] |			
  }
end



program set_auto_stop
  args section 
  capture setvar ${lang}`section'_auto_stop , vlabelname(yesno) label(Could the child not complete any ${lang}`sectionName' questions?) destring order(b(${placeholder})) 
end



program section_qc_check
  args section length equate_val
  
*******************************************************************
*                                                                 *
*  This program handles I/O (Displaying information to the user)  *
*  and QC checks that ensure the integrity of the data.  If the   *
*  data fails any of these tests, the program warns the user      *
*                                                                 *  
******************************************************************* 

  // Setup: Determining the section
  if "`section'"=="unt_read_comp" local unt "unt_"
  else if "`section'"=="sublvl2" local sec "sub"
  else if "`section'"=="addlvl2" local sec "add"
  
* OUTPUT: Section name
  capture confirm variable ${lang}${section}_score  
  if !_rc display in smcl _col(1)  in green "{c |} ${sectionName}" _c // Display section
 
* OUTPUT & QC: Checks that there are item levels to substantiate the score and other summaries
  if !_rc & "`length'"=="0" display in smcl _col(34) "{c |}" in red " NONE" in green "{col 42}{c |}" _c
  else if !_rc display in smcl _col(34) "{c |} " as result "`length'" in smcl "{col 42}{c |}" _c
  
* OUTPUT: Display equate value
  if !_rc di in smcl  _col(44) "`equate_val'" _col(51) "{c |}" _c
  if !_rc & "`length'"=="0" display in smcl _col(102) "{c |}"
  
* QC: Checks that there are indeed item levels when the 'readword' fix is specified
  capture confirm variable ${lang}`unt'oral_read_attempted
  if _rc & colsof(`unt'readWordNeeded) & "`section'"=="`unt'read_comp" display in red _col(53) "`unt'readword() but no oral_read_attempted " _c

* QC: For if math has both leveled and non-leveled sections simultaneously
  if ("`section'"=="addlvl2" | "`section'"=="sublvl2") {
    capture confirm ${lang}`sec'_score
	if !_rc display _col(53) in red "`sec' both leveled and non leveled " _c
  }
  
* QC: Determines if time remain is either below 0 or above 60
  capture confirm variable ${lang}`section'_time_remain
  if !_rc {
	quietly: summarize ${lang}`section'_time_remain
    if(r(min)<0) display _col(53) in red "time remain < 0! " _c
	if(r(max)>60) display _col(53) in red "time remain > 60 (counting UP?)" _c
  }

 * QC: Similar to the time remain, checks that the minimum and maximum values are appropriate
  capture confirm variable ${lang}`section'_score_pcnt
  if !_rc { 
    quietly: summarize ${lang}`section'_score_pcnt
    if(r(max)>1 & r(max)<.) display _col(53) in red "score pcnt > 100% " in green _col(102) "{c |}"
    else if r(max)<1 display  _col(53) in red "no 100% in score pcnt! " in green _col(102) "{c |}"
    else  display in smcl _col(102) "{c |}"
  }
end
}

{/*Super Summary FUNCTIONS*/
program define create_general_summary
  args section name qclimit
  local lang "$lang"
  capture confirm variable ${lang}`section'_time_remain ${lang}`section'_score
  if !_rc {
	capture drop ${lang}`name'
	quietly: gen ${lang}`name'=${lang}`section'_score/(1-(${lang}`section'_time_remain/60))
	if "`name'" == "unt_orf" quietly: replace ${lang}`name'=(${lang}`section'_score/(1-(${lang}`section'_time_remain/180)))/3
  }
  capture confirm variable ${lang}`name', exact
  if !_rc {
	//QC Check
	capture confirm variable ${lang}`section'_time_remain ${lang}`section'_score
	if _rc display in red "${lang}`name' exists but ${lang}`section' score or time remain do not exist! "
	quietly: summarize ${lang}`name'
	if r(max)>`qclimit' & r(max)<. display in red "`name' > `qclimit' for at least one student! "
	if r(min)<0 display in red "${lang}`name' < 0!  Check if ${lang}`section'_time_remain is counting up rather than down. "
    setvar ${lang}`name', label(${superSummaryVarLabel}) order(b(${placeholder}))
  }
end


program define create_read_comp
  args section name qclimit varlabel
  if "`name'"== "unt_read_comp_attempted_pcnt75" | "`name'"== "read_comp_attempted_pcnt80" local type "attempted"
  else local type "score"
  if "`section'"=="unt_read_comp" {
    local unt "unt_"
	local cutoff "75"
  }
  else	local cutoff "80"
  if "`type'"=="attempted" capture confirm variable ${lang}`unt'read_comp_score ${lang}`unt'read_comp_attempted
  else capture confirm variable ${lang}`unt'read_comp_score
  if !_rc { 
    capture drop ${lang}`name'
	*Generate and label a new ones
    quietly: gen ${lang}`name'= (${lang}`unt'read_comp_`type'_pcnt>=`cutoff'/100) if ${lang}`unt'read_comp_`type'_pcnt<.
	read_comp_excep ${lang} `unt' `cutoff'
	setvar ${lang}`name', vlabelname(yesno) label(${superSummaryVarLabel}) order(b(${placeholder}))
  }
end 


program define read_comp_excep
  args cutoff unt
   capture confirm variable ${lang}`unt'oral_read1
   if !_rc capture: recode ${lang}`unt'read_comp_score_pcnt`cutoff' (.=0) if ${lang}`unt'oral_read_attempted < `unt'readWordNeeded[1,1]
   else capture: recode ${lang}`unt'read_comp_score_pcnt`cutoff' (.=0)
end
}

{/*Cleanup FUNCTIONS*/
program define combine_maths
  args mlevels
  **Determine which section, and how many questions in each level.
  local mLevelsWords = wordcount("`mlevels'")
  forvalues value=`mLevelsWords'(-2)1 {
	local key = `value' -  1
	local cutoff : word `value' of `mlevels'
	local ++cutoff
	local section : word `key' of `mlevels'
	capture ren ${lang}`section'lvl2# ${lang}`section'#, renumber(`cutoff')
    capture ren ${lang}`section'lvl1# ${lang}`section'#
  }
end
}
mata:
string matrix create_matrix_from_data(){
  string matrix main_matrix;
  real scalar obs, var;
  main_matrix = J(st_nobs(),st_nvar(),"")
 
  for(obs=1; obs<=st_nobs(); obs++){
    for(var=1; var<=st_nvar(); var++){
	  if(substr(_st_sdata(obs,var),1,1)!=".") main_matrix[obs, var] = st_isstrvar(var) ? _st_sdata(obs,var) : strofreal(_st_data(obs,var));
      else main_matrix[obs, var] = "";
    }
  }
  return(main_matrix)
}

end

