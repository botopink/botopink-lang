# Decision 968 — std's `Scope` keeps the tree of cells by place: a component's cell is found again at its place from one render to the next and dropped when the place is not met; it holds the hooks' slots of every value-answering `use`, in the order written, and takes its parent's contexts anew at each render; `#[key(expr)]` is written at the call; `{ component -> … }` is 574's factory, never a component; restates what stands of 816, 817 and 818 under 966, replacing them.

[draft/main.bp](draft/main.bp)
