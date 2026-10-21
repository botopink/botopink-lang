# optional_chain_absent_array_length

Decision 330: at the first absent link of a `?.` chain the whole chain is absent. A chain through an optional record's
optional array ending in a method, `h?.fields?.length()`, is absent when `h` is (`val h: ?Form = null`) and when `fields`
is, so `?? 0` answers `0` — also when the chain is bound first (`val n = h?.fields?.length()`).
