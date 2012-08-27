program forvars
syntax varlist, use(str) do(str)
foreach variable in `varlist' {
  `use' `variable' `do'
}
end
