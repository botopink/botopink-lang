# optional_chain_present_array_length

Decision 330: `?.length()` over a present optional array answers its length. `f?.fields?.length()` on a present `Form`
with two fields answers `2`, and on a `Form` whose `fields` is `null` or an absent `Form` it is absent, so `?? 0`
answers `0`. A function expression's parameter typed `?Holder[]` (`hs?.length() ?? 0`) given a present array answers its
length, on every target.
