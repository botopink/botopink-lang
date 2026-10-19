# Decision 589 — (f), a sixth option: the prelude is the items marked `#[bpp.htmlPrelude]` where they are declared, one by one.

The example has two packages. `draft/kit/` is `kit`, the package the application names in `"bpp"`. Its `html.bp` holds the `#[bpp.html]` unfold target, which answers the markup's text. Its `components.bp` marks two functions where they are declared, `#[bpp.htmlPrelude] pub fn Card` and `#[bpp.htmlPrelude] pub fn Badge`. Those two items, one by one, are the prelude. `cardCount` is `pub` but unmarked, so it is `kit`'s API, which an importer may name but a `.bpp` never sees for free. `shout` lives under `internal/` and is private to `kit`. No `prelude.bp` and no `pub val prelude = bpp.Prelude()` exists, and no root re-exports anything.

The application's `home.bpp` imports nothing. It writes `<Card title={title}><Badge text="new" /></Card>`, and both names resolve through the prelude, because the file binds neither itself. `components.bp`'s own imports, `bpp` and `internal.text.shout`, stay private to that module and reach no `.bpp`. `main` calls the unfolded `Home()` and prints what `kit`'s `html` answers for that markup.

If `home.bpp` imported or declared its own `Card`, or if a second marked item named `Card`, the build would be refused at the second place, naming the first (`src/components.bp`). The same goes for the mark on an item without `pub`, or on an item re-exporting another package's.

In the promoted cell `kit/` becomes `deps/kit`, which the cell's `botopink.json` declares as a dependency and names in `"bpp"`. A draft carries neither.

Cells in this repository that also bear on it: `modules/bpp_prelude_holds_declaration`, `modules/bpp_prelude_twice`, `modules/bpp_prelude_on_fn`, `modules/bpp_roles_found`.

[draft/main.bp](draft/main.bp)

[draft/home.bpp](draft/home.bpp)

[draft/kit/html.bp](draft/kit/html.bp)

[draft/kit/components.bp](draft/kit/components.bp)

[draft/kit/internal/text.bp](draft/kit/internal/text.bp)
