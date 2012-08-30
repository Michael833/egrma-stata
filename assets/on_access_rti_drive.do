local current_egrma_version = 2

if `s(egrma_version)'<`current_egrma_version' {
	noisily display in red "Your version of the RTI EGRA package is deprecated | updating you now"
	rtiupdate
	noisily display in gr "Done. Type -program drop _all- or restart Stata."
}
