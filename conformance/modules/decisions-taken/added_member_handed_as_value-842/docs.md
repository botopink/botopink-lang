# Decision 842 — a member a decorator adds and then needs is held as a value: the decorator writes the function once, adds it and hands that value to its executor and its other members — never read back through `decl`.

`#[endpoint(Api(url: "api.local"))]` holds its member in a `val`: `make`, written once as `fn() -> decl { … }`, the
handle in its return type (627) typed by the contract `Endpoint`. The decorator adds it to `Api` as `make`, and hands
the same value to its other member `check` (`make().host()`) and to its executor — a `fn` literal is a literal (759)
and a tree spliced into a tree (575 (4)), so each read of `make` is the literal itself. Nothing reads the added member
back through `decl`. The executor prints `api.local registered` before `main`, which prints `api.local` and
`api.local checked`.

Cells that also bear on it: `modules/decisions-taken/decorator_member_local_not_literal-759/cases/decorator_member_local_not_literal`.

[cases/added_member_handed_as_value/src/main.bp](cases/added_member_handed_as_value/src/main.bp)
