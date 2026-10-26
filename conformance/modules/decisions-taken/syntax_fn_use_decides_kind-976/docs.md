# Decision 976 — A function with a `syntax` parameter is one kind — a build body over code — and the place it is used decides how it is read: `#[f]` applies it as a decorator, `f(e)` expands it at the call; each use is checked by its own rules against the one declared type, a body returning code admitted at the call and refused at the annotation; `isSyntaxExprFn` goes; restates 907 with 962 folded in, replacing it.

[cells/syntax_fn_use_decides_kind/src/main.bp](cells/syntax_fn_use_decides_kind/src/main.bp)
