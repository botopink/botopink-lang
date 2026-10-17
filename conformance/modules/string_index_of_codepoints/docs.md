# string_index_of_codepoints

The reference text this cell shows (from `conformance/docs.md`, § Primitives):

> A `string` is indexed by codepoint on every target (decision 320): `length`,
> `at`, `slice`, `indexOf` and `lastIndexOf` count codepoints — `"e\u{301}".length`
> is 2 and its `.at(1)` is `"\u{301}"`, `"👍".length` is 1 — never UTF-16 units,
> bytes or grapheme clusters, so the index `indexOf` answers is the one `at` and
> `slice` read back. A JavaScript host template receives and answers codepoint
> indices.
