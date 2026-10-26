# array_literal_union_elements

The reference text this cell shows (from `conformance/docs.md`, § Union types, `unknown`, and `is`):

> The elements of an array literal that disagree make the union of their types
> (`[3, "abcd"]` is `(i32 | string)[]`), and each element read back — printed,
> iterated, by index or `at`, passed to a parameter of the union — is the member it
> is, whether the union is inferred or written:
