# Decision 237 — A template capture carries only the bindings whose name appears as a word in the captured text (`<Card title="x"><Badge/

The template `deps`, declared in the build layer ([draft/comptime/capture.bp](draft/comptime/capture.bp)), answers the names of the bindings `compiler.bindings(q)` gives it for its text. The capture holds only the bindings whose name appears as a word in that text.

The first call's text is `<Card title="x"><Badge/></Card>`. Its words `Card` and `Badge` name two types of `main`, so the call answers `[Card, Badge]`. `title` and `x` name nothing in scope, so they add nothing. The second call's text is `"cfg-0"`, which has no word naming a binding, so it answers `[]`. The third call repeats the first text and gets the same answer, `[Card, Badge]`: one declaration's capture is the same every time. A `compiler.lookup(q, "Footer")` in the body would be a located comptime error, because `Footer` is not a word of the text, whether or not a `Footer` were declared.

The program prints `[Card, Badge]`, `[]` and `[Card, Badge]`.

Cells in this repository that bear on it: `modules/template_bindings_decls`, `modules/template_lookup_decl`.

[draft/main.bp](draft/main.bp)
