# template_note_on_mismatch

The reference text this cell shows (from `conformance/docs.md`, § Functions expanded at their call):

> **A call is typed by the code it built** (decision 426). The type of a
> template call is the type of the code the template built for that call,
> computed at build: no free `T` of the signature is left, so `fn data<T>(…) ->
> T` answers `string[]` at one call and `i32` at another. The template's
> answer is a bound the built code fits — `unknown` holds anything, so `->
> unknown[]` keeps the call's `string[]` —, and code outside it is
> refused in the template, at its `build` (`template-build-outside-bound`). The
> call then meets the type expected where it stands as any expression does:
> `` val n: i32 = names @`cities`; `` is `type mismatch: expected i32, got string[]`
> at the call. The template never reads the expected type, so what it builds is
> decided by its text; `q.note(message)` gives the reason, attached to an error
> reported at its call (`— note: …`).
