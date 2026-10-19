# meta_field_compared_by_owner

Fields read back from a typed meta record are run-time values (decision 631):
`by` read twice is one value, `by` and `then` (`.pages`, `.title` of `Book`)
are two, each prints its `name`, and each keys a `Dict`.

`Sort(by: .pages, then: .title)` on `Book` — `true`, `false`, `pages title`, `4`, `30`.
