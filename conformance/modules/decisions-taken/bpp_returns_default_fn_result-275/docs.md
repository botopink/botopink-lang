# Decision 275 — The function a `.bpp` file unfolds to returns the `R` of the default function's declared `@ExprCustom<R>`, read by the t

The function a `.bpp` file unfolds to returns whatever the target function declares. Here the package the manifest
names in `"bpp"`, the fixture [draft/deps/markup/src/markup.bp](draft/deps/markup/src/markup.bp), declares its
`#[bpp.html]` default function `-> i32` and answers the markup's length in codepoints. So
[draft/Badge.bpp](draft/Badge.bpp), which has a header with `Props` and a statement, and
[draft/Spacer.bpp](draft/Spacer.bpp), which is markup only, both unfold to functions returning `i32`. `main` binds
each call to an `i32`, prints `20` and `5`, and adds the three results as plain integers, `45`. The toolchain read
that type from the target function's signature. It names no library's type, and with `rakun-bpp` as the `"bpp"`
package the same reading gives `View`, whether or not the header uses `use` or `await`. The manifest is
[draft/botopink.json](draft/botopink.json).

Cells in this repository that also bear on it: `modules/bpp/cells/bpp_unfold_props`, `modules/bpp/cells/bpp_roles_found`.

[draft/main.bp](draft/main.bp)
