# excluded_target_literal_entry

A cell whose own tree holds a workspace manifest listing a literal entry that is no directory
(`deps/botopink.json`, as rakun's service cells do) beside a symlinked package (`deps/shared`). The wasm build its `"targets"` leave out
is read in place, so the build refuses the cell on its host binding and not on the entry the scratch copy lacks
(decision 548, 144 B-132). {src/main.bp}
