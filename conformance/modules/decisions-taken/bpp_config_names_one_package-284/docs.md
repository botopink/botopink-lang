# Decision 284 — Configuration in JSON, case by case.

The whole `.bpp` configuration is one key of the manifest, [draft/botopink.json](draft/botopink.json):
`"bpp": "markup"`, one package name and no table of roles. That package, declared as an ordinary dependency, is a
fixture and not `rakun-bpp`. The toolchain finds its roles by std's `bpp` annotations alone. In
[draft/deps/markup/src/markup.bp](draft/deps/markup/src/markup.bp), `#[bpp.html]` marks the markup's unfold target,
exactly once in the package. In [draft/deps/markup/src/words.bp](draft/deps/markup/src/words.bp),
`#[bpp.htmlPrelude]` marks `shout` for the prelude. [draft/Greeting.bpp](draft/Greeting.bpp) calls `shout` by its
plain name, with no import, and unfolds onto `markup`, so `Greeting()` prints its markup text, `<p>{loud}</p>`.
`main` imports `shout` like any item of the package and prints `CONFIGURED!`. No other key of the manifest, no file
name and no package name tells the toolchain anything about `.bpp`.

Cells in this repository that also bear on it: `modules/bpp/cells/bpp_roles_found`, `modules/bpp/cells/bpp_file_without_key`,
`modules/bpp/cells/bpp_html_missing`, `modules/bpp/cells/bpp_html_twice`, `modules/decisions-taken/std_bpp_role_annotations-361/cases/bpp_prelude_on_fn`.

[draft/main.bp](draft/main.bp)
