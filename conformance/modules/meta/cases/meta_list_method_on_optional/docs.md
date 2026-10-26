# meta_list_method_on_optional

The reference text this cell shows (from `conformance/docs.md`, § Optionals):

> A method written after a `?.` field that is a list is the list's: `meta(Tags)?.list.join(",")`
> reads the payload's list and joins its elements as the list's element type says, and
> `(opt?.list ?? []).join(",")` keeps that element type across `??` — an empty default
> adds none, so a list of strings joins as strings on every target:
