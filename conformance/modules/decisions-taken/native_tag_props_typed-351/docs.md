# Decision 351 — A native tag's attributes are typed the way React types its intrinsic elements, in botopink's own shapes, and `prelude.bp` is the intrinsic table.

The example builds the props of a native `<a>` the way the markup library's intrinsic table declares them, as records with defaults layered with `Type.merge`. `GlobalAttrs` holds the attributes every element takes (`id`, `class`, `hidden`, `tabIndex`). `AriaAttrs` holds the typed `aria-*` fields, so `aria-label` is `ariaLabel`. `AnchorAttrs` holds the anchor's own: `href`, and `target`, whose closed set of values is the enum `Target`. `pub val AnchorProps = Type.merge(Type.merge(GlobalAttrs, AriaAttrs), AnchorAttrs);` is the element's props type, an ordinary type usable wherever a type is named.

Each field is a `?T = null`, which is absent when `null`, or a `bool`, which is written bare when `true` and absent when `false`. A number is an `i32`, and the rest is `string`. The builder `a` takes the props record as its first parameter, as a component takes its props, and writes HTML's names: `tabIndex` becomes `tabindex` and `ariaLabel` becomes `aria-label`.

The program prints `<a href="/docs" target="_blank" tabindex="2" aria-label="Docs" hidden>Read</a>`, and then `<a href="/">Home</a>` for a record that sets only `href`. Because the props are a record, a misspelt attribute (`AnchorProps(hreff: "/x")`, which is `<a hreff="/x">` in markup) is refused at `hreff`, and `tabIndex: "abc"` is refused at the value. The markup half, where a tag exists only when the prelude names its builder, a custom element is an error at the tag, and `onClick` is refused at its name, is the markup library's.

Cells in this repository that bear on it: `modules/derived_type_declarations`, `modules/derived_type_merge_duplicate`.

[draft/main.bp](draft/main.bp)
