# memo_computed_once_per_instance

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> **Memo** (decisions 755, 771, 774). `val v = use memo({ -> make });` is std's
> hook `hooks.memo<T>(make: fn() -> T) -> Component<T>`, imported as any std
> function (`import {hooks.memo} from "std"`): it answers the value `make`
> computed on the component instance's first render, kept for that instance and
> never recomputed — there is no dependency list. A component instance is the
> value one `Page(…)` call makes: when that value is made, one slot is allocated
> per `use memo` position in the body; the first render fills the slot, and a
> later render of the same value reads it. Another `Page(…)` call is another
> instance, with slots of its own. The slot is a process-dictionary entry on
> erlang and beam, a closure cell on commonJS and a heap cell on wasm.
