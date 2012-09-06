local current_egrma_version = 5
egrmaversion
if `s(egrma_version)'<`current_egrma_version' {
	noisily display in red "Your version of the RTI EGRA package is deprecated | updating you now"
	rtiupdate
	program drop egrmaversion
	noisily display in gr "Done. Type -program drop _all- or restart Stata."
}
