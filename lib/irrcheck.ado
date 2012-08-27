capture program drop irrcheck
program define irrcheck
	syntax [using/] , [EXCELoptions(str) exclude(str) SEParately(str) GENerate(str)] 

*********************************************************************************
*																				*
*	IRRCHECK - a program for scoring admin reliability on EGRA and EGMA tests  	*
*  This program compares each observation (each admin) to a key admin which we  *
*  call the 'gold standard' admin. First the program either pulls in the excel  *
*  dataset or else uses the one currently in memory. It recodes all the 		*
*  variables to dummies, which contain whether each observation matches the 	*
*  'gold standard'.  It then finds the percent correct and produces nice, 		*
*  graphical output.															*
*																				*
*********************************************************************************
global codebook_handle "\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\Codebook for EGRA & EGMA.xlsx"
global local_codebook_handle "`c(sysdir_plus)'Codebook for EGRA & EGMA.xlsx"

{ /* Getting codebook info */
 capture confirm file "$codebook_handle"
  if !_rc & "`update'"==""{
    preserve
	
	import excel using "$codebook_handle", clear firstrow sheet("Demographics")
    create_matrix_from_data demographicInfo
	
	import excel using "$codebook_handle", clear firstrow sheet("Test Sections")
    create_matrix_from_data testSectionInfo
		
	save_matrices demographicInfo testSectionInfo using "$local_codebook_handle"
	
	restore
  }
  else get_matrices demographicInfo testSectionInfo using "$local_codebook_handle"

}
{ /* Checking consistency */
	capture summ goldstandard
	if _rc {
		di as err "goldstandard not found"
		exit
	}
	if r(sum)> 1 {
		di as err "more than one gold standard"
		exit
	}
	else if r(sum)==0 {
		di as err "no gold standard admin"
		exit
	}
}	
{ /* Generating IR scores */	
// varlist should include variables NOT to be counted in irrcheck
local generate "PNA"

// Open the data.  should be in excel format 
if `"`using'"' !="" {
	if "`exceloptions'" == "" {
		local exceloptions "sheet(Summary sheet) first"
	}
	import excel using `"`using'"', `exceloptions' clear 
}

gsort -goldstandard //gold standard will be 1st obs

mata: st_local("all_vars", invtokens(st_varname(1..st_nvar()))) //get the names of all variables and concatenate into a string - make into a local
local used_vars ""
local nused_vars: list sizeof used_vars
local exclude "`exclude' goldstandard"

//egrmaclean `all_vars'
preserve

forvalues i=2/$possiblesections {


* Set up macros that keep track of important values for the section  
  create_obs_global section sectionName sectionValueLabelName using testSectionInfo, obs(`i')
  local length = 1
  
* Item level loop  
  while 1 {
  //Rename and set infomation
    capture: ren ${section}_`length' ${section}`length'
    capture: ren ${section}0`length' ${section}`length'
	capture confirm variable  ${section}`length'
	if _rc continue, break
	
	local correct_value = ${section}`length' in 1
	
	quietly replace ${section}`length' = . if ${section}`length'==`correct_value' & `correct_value'>=1 & `correct_value'<.
    quietly replace ${section}`length' = 1337 if ${section}`length'==`correct_value' & `correct_value'==0
	quietly replace ${section}`length' = 0 if ${section}`length'!=`correct_value' & ${section}`length'!= 1337 & ${section}`length'<.
	quietly recode ${section}`length' (1337=1)
	local used_vars "`used_vars' ${section}`length'"
    local ++length
  }
  local --length  // Decrement because we exit the loop only after we go one too far


	*********************************************************************************
	* Recode the time remain variable to correct if it's within 1 sec of standard	*
	*********************************************************************************
	capture local correct_value = ${section}_time_remain in 1
	if !_rc {
		quietly replace ${section}_time_remain = 1337  if ~inrange(${section}_time_remain, `correct_value'-1, `correct_value'+1)
		quietly replace ${section}_time_remain = 1 if inrange(${section}_time_remain, `correct_value'-1, `correct_value'+1) 
		quietly recode ${section}_time_remain (1337=0)
		local used_vars "`used_vars' ${section}_time_remain"
	}	
}

//add it up and save to a mata matrix, so that we can access these values after the restore
tempvar pna nused_vars
quietly egen `pna' = rowtotal(`used_vars')
quietly egen `nused_vars' = rownonmiss(`used_vars')
quietly replace `pna' = `pna'/`nused_vars'
mata: pna = st_data(., st_varindex("`pna'"))

//and if the user specified a separate varlist
if "`separately'"!=""{
	tempvar sep_pna sep_nused_vars
	quietly egen `sep_pna' = rowtotal(`separately')
	quietly egen `sep_nused_vars' = rownonmiss(`separately')
	quietly replace `sep_pna' = `sep_pna'/`sep_nused_vars'
	mata: sep_pna = st_data(., st_varindex("`sep_pna'"))
}

restore

//Now return our information to the dataset
mata: index = st_addvar("float", "`generate'")
mata: st_store(., index, pna)

if "`separately'"!=""{
	mata: index = st_addvar("float", "sep_`generate'")
	mata: st_store(., index, sep_pna)
}
gsort -PNA
}



*********************************************************************************
*  				Producing graphical output and ranking IRs						*
*********************************************************************************
//Bar graph of scores
local N = _N
forvalues i = 1(7)`N' {
 local max = `i' + 6
 if `max' > `N' local max = `N'
 graph bar (asis) PNA in `i'/`max', over(admin_name)
 graph export "scores for admins `i'-`max'.png", replace
}

end

capture {
program define create_obs_global 
  syntax namelist using/, obs(int)
  local i = 1
  foreach word in `namelist' {
    mata: st_global("`word'", `using'[`obs',`i'])
    local ++i
  }
end

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

}
