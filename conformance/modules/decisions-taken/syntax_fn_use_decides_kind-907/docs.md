# Decision 907 — A function with a `syntax` parameter is one kind — a build body over code — and the place it is used decides how it is read: `#[f]` applies it as a decorator, the annotated declaration its first `syntax` parameter (663, 716); `f(e)` expands it at the call, the written expression its `syntax` parameter (719, 841); each use is checked by its own rules against the one declared type; the signature decides nothing and `isSyntaxExprFn` goes.

[cells/syntax_fn_use_decides_kind/src/main.bp](cells/syntax_fn_use_decides_kind/src/main.bp)
