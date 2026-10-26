# dict_bump_on_module_var

`Dict.bump` on a module `var` is the plain `Dict` method (decision 340), and the write
`counts = counts.bump(k, n)` reads the `var` it writes, so on the BEAM it is the
compare-and-swap of decision 547 (ii): concurrent bumps of one key lose none.
