# deep_recursion_rounds

A recursion 5000 deep, run 200 times: each level makes a string that lives until the level returns, so 5000 are live
at the bottom of a round and none once the round is over. A million calls in all, printing `9778600` on every target;
on wasm the strings of a finished round are collected.
