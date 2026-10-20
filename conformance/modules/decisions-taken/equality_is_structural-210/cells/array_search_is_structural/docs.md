# array_search_is_structural

`indexOf`, `lastIndexOf` and `contains` over an array compare by `==`, which is structural (decision 210): a record, a tuple, a nested list or an enum variant with a payload is found by its parts, not by reference. `[P(1, "a")].indexOf(P(1, "a"))` is `0` on every target.
