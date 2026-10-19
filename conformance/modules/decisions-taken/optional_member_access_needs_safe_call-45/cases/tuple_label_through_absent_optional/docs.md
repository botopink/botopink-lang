# tuple_label_through_absent_optional

The reference text this cell shows (from `conformance/docs.md`, § Optionals):

> A tuple's label read through `?.` on an absent element is absent (`es.at(3)?.a ?? 0`
> is `0`), and a present element's label is its value, `0`, `false` and `""` included
> — never taken for absence:
