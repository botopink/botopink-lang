# Decision 278 — Template directives are **annotations written inside the tag**, in the attribute zone: `<Carousel #[clientVisible("200px

`page.bpp` writes every directive as an annotation inside its tag, among the attributes. `<Carousel #[clientVisible("200px")] images={12} />` makes `Carousel` an island hydrated when it comes within 200px of the viewport. The server renders its `12 images` once, and `clientVisible` records the `Hydrate` meta the page reads. `Carousel` carries `#[client]`, which `html` checks for every `Hydrate`. `<LocalClock #[clientOnly] />` is one function with one meaning, rendered only in the browser: the server writes no call for it, so its `<time>` is not in the server's output, and its node does not enter the page's hooks.

Element directives are values or annotations, never `prefix:name`. `{raw(note)}` writes `note` unescaped, so the bold tag survives in the `div`. In the paragraph the same `{note}` arrives escaped. `class={classList(["lead", "wide"])}` joins the classes to `lead wide`. `<style #[isInline]>` keeps its rule inline in the page.

Each annotation is a function resolved in the caller's scope like a tag name. `clientVisible`, `clientOnly`, `isInline`, `raw` and `classList` reach the `.bpp` through the prelude, so the file imports only the two widgets.

A draft carries no manifest and no dependency, so the `"bpp": "rakun-bpp"` key is what the promoted cell's `botopink.json` will add.

Cells in this repository that also bear on it: none.

[draft/main.bp](draft/main.bp)

[draft/widgets.bp](draft/widgets.bp)

[draft/page.bpp](draft/page.bpp)
