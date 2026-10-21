# Decision 285 — The toolchain knows these things about `.bpp`:

The toolchain knows two things about `.bpp`: the package the manifest's `"bpp"` key names
([draft/botopink.json](draft/botopink.json)), and the declarations std's four `bpp` annotations mark in it. Here that
is only `#[bpp.html]` on [draft/deps/markup/src/markup.bp](draft/deps/markup/src/markup.bp). The files
[draft/app/layout.bpp](draft/app/layout.bpp) and [draft/app/blog/page.bpp](draft/app/blog/page.bpp) carry the names a
file-convention router gives a layout and a page. The same package even declares decorators called `layout` and
`page` ([draft/deps/markup/src/comptime/roles.bp](draft/deps/markup/src/comptime/roles.bp)), and each would refuse
the declaration it annotates. The toolchain applies neither: a file's name gives it no role and no decorator, and the
manifest has no `"bppKinds"`. Both files unfold to plain anonymous default functions, which `main` imports by their
module paths and calls. The program prints `<main>site</main>` and `<article>{props.slug}</article>`. Making a page
of a file is the framework's rule. The route table `rakun-app` generates at build calls its `page` / `layout` on each
unfolded function, and a decorator written in the header, on the line before the separator, annotates the unfolded
function.

Cells in this repository that also bear on it: `modules/bpp/cells/bpp_roles_found`,
`modules/decisions-taken/bpp_decorator_in_header-221/cells/bpp_decorator_last_line`.

[draft/main.bp](draft/main.bp)
