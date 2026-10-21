# syntax_fn_use_decides_kind

The reference text this cell shows (from `conformance/docs.md`, § Functions expanded at their call):

> A function with a `syntax` parameter is one kind, and the place it is used
> decides how it is read (907): `#[f]` applies it as a decorator, the annotated
> declaration its first `syntax` parameter (663, 716); `f(e)` expands it at the
> call, the written expression its `syntax` parameter. The signature decides
> nothing: one declaration may be annotated and called.

`log(syntax e: unknown) -> void` annotates `answer` and is called on `n` (`n = 3`) and on `n + 4` (`an expression = 7`); `answer` prints `42`.
