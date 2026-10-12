# fold_split_join_lambda

A `fold` lambda whose accumulator is a string can chain string and array methods on it: `acc.split(c).join("")` removes
every `c` from `acc`, and the answer is the same on every target.
