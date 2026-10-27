# type_token_labelled_field

A record whose field is a run-time `type<T>` takes the type written for it the same way labelled as positionally (decision 758): `Holder(owner: Book, label: "a")`, `Holder(label: "c", owner: Book)` out of declaration order and `Holder(Book, "d")` all carry the type's identity, and `holds(b, a.owner)` tests `b is t` at run time on every target.
