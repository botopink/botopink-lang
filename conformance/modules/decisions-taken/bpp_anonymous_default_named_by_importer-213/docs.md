# Decision 213 — A `.bpp` file becomes the module's anonymous `pub default fn` (289), named by its importer after the file: `components/P

Each `.bpp` file under `components/` unfolds to its module's anonymous `pub default fn`, and the importer gives it
its name. [draft/components/PostCard.bpp](draft/components/PostCard.bpp) is already named the way it is called, so
`import {components.PostCard};` binds `PostCard` with no alias, and `PostCard(title: "Hello")` passes its `Props`
field by label. [draft/components/site_footer.bpp](draft/components/site_footer.bpp) is named otherwise. No case
conversion turns `site_footer` into `SiteFooter`, so the import writes the alias, `as SiteFooter`.
[draft/components/not-found.bpp](draft/components/not-found.bpp) has a name that is no identifier. It is written
between backticks and given an alias, `` components.`not-found` as NotFound ``. The markup is unfolded onto the
`#[bpp.html]` function of the package the manifest's `"bpp"` key names. Here that is the fixture
[draft/deps/markup/src/markup.bp](draft/deps/markup/src/markup.bp), declared in
[draft/botopink.json](draft/botopink.json), which answers the markup's text. The three lines print each file's markup
as written. `import PostCard from "components/PostCard"` would be `module-import-with-from`: the module is imported by
its path in braces.

Cells in this repository that also bear on it: `modules/decisions-taken/anonymous_default_function-289/cells/bpp_unfold_without_props`,
`modules/decisions-taken/backtick_escaped_identifier-561/cells/bpp_not_found_aliased`,
`modules/decisions-taken/backtick_escaped_identifier-561/cells/bpp_not_found_unaliased`, `modules/bpp/cells/bpp_unfold_props`.

[draft/main.bp](draft/main.bp)
