# Decision 200 — `html` is the `pub default fn` of the core member `jhonstart`, carrying `bpp`'s `#[html]` (`#[bpp.html]`, 361) — `import

The example imports `html` the way the decision writes it: `import html, {Element, renderToString} from "rakun-bpp";`. The bare `html` is the package's default function, and the braces bring in two of its other items. jhonstart's core is now the `rakun-bpp` package (724), and no separate `-html` package exists to import it from.

`greeting` calls `html` as a template, `` html @`<p class="greet">Hello, {name}</p>` ``, and gets an `Element` back. The first line renders that paragraph with `Ana` in the hole. `badge.bpp` writes no call at all: its markup is unfolded onto the same function, because `html` carries `#[bpp.html]` and the application's manifest names `"bpp": "rakun-bpp"`. `<Badge label="new"/>` renders the span. One function serves both spellings, and the toolchain finds it by the mark, never by its name.

A draft carries no manifest and no dependency, so the `"bpp"` key and `rakun-bpp` are what the promoted cell's `botopink.json` will add.

Cells in this repository that also bear on it: `modules/bpp/cases/bpp_roles_found`, `modules/bpp/cases/bpp_html_missing`, `modules/bpp/cases/bpp_html_twice`.

[draft/main.bp](draft/main.bp)

[draft/badge.bpp](draft/badge.bpp)
