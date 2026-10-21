# memo_computed_once_per_instance

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> **Memo** (decisions 755, 816, 818 (1)). `val v = use memo({ -> make });` is std's
> hook `hooks.memo<T>(make: fn() -> T) -> Component<T>`, imported as any std
> function (`import {hooks.memo} from "std"`): it answers the value `make`
> computed on the first render of its cell, kept while that cell stands and
> never recomputed — there is no dependency list. `use memo` is a call of the
> body like any other, numbered with them, and takes a child cell of the
> body's cell at its place; its slot is that cell's. A cell stands from one
> render to the next while its place is met again — the same root run again,
> the same written call, the same item count or key (decisions 816, 819, 820)
> —, so two runs over one `Scope` root share it and a fresh root starts empty.
