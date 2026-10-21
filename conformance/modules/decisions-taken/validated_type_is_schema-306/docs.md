# Decision 306 — The type is the only schema, and `#[schema]` becomes `#[validated]`.

The example writes no schema value. `Signup` is an ordinary record with `#[validated]` on it. Its field markers say what a value alone could not: `#[email]` for the address, `#[minValue(18)]` for the age, and `#[each(email, lowercased)]` for every guest. The one decorator gives the type its members, both the parsing ones and the checking ones. `Signup.parse(doc)` decodes a document into the record. The first document passes and prints `ana@x.org 30 bo@x.org`. The second fails three ways, and the report names each field and the rule it broke: the address, the age, and the guest that is not lowercase. `validate()` checks a record built in code, and the one aged 17 answers `false`.

`Email` shows a one-field record encoded as its field. With `#[validated(transparent)]`, `encode` writes the bare string `"ana@x.org"` rather than an object.

`fieldNames` stands for another library that takes the type: a `comptime` type parameter, refused at build unless the type's `typeInfo` carries the `Validated` meta. `fieldNames(Signup)` prints `email,age,guests`. A plain record passed there would fail the build at the argument. The program never reaches `Schema<T>`, a `Codec`, a `schemas.*` combinator or a `checks.*` function, because none of them is public.

The compiler's part is the decorator's typed members and the `comptime` type parameter read through `compiler.typeInfo`. The markers are validation's, and the example imports `validation`, which this repository's drafts declare no dependency on.

Cells in this repository that also bear on it: none.

[draft/main.bp](draft/main.bp)
