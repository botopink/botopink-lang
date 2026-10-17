# hole_any_call_at_build

The reference text this cell shows (from `conformance/docs.md`, § Template functions):

> **A hole is the template's** (decision 577 (1), (5)). `${…}` and `{…}` in a
> template text are the sub-language's own syntax: the template finds them in
> `compiler.text(q)` and splices each hole's expression into the code it builds,
> where it is typed in the caller's scope; the template never reads a hole's
> value. The code it builds is then evaluated as any code is: what the compiler
> folds at build (decisions 355, 376, 380) it folds, and a value that raises
> there is refused at the call that raised (§ Compile-time evaluation), with a
> `called from` line for each call of the chain (decision 532):

Decision 577 (5) amends 355 and 380 where they read a language hole: the template splices each hole (`textOf(<hole>)`) and no longer tells a hole known at build from one computed at render, so every line is the spliced text.
