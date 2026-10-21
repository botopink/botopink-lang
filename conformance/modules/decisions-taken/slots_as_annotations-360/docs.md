# Decision 360 — Slots work as Astro's, in botopink's annotation form — never props.

`panel.bpp` declares its slots only by writing them in its template. `<Slot />` is the default slot. `<Slot name="footer">no footer</Slot>` is the `footer` slot, and its content, `no footer`, is the fallback. The panel has no `Props`, and no field stands for its content. Its header asks `use hasSlot("footer")` and writes the answer as `data-footer`.

`main` fills the panel three ways. In the first call, the unannotated `<p>body</p>` goes to the default slot and `<small #[slot("footer")]>by Ana</small>` goes to the footer, so the section renders with `data-footer="true"` and both nodes. In the second call nothing fills the footer: `hasSlot` answers `false` and the fallback `no footer` renders. In the third, `<Fragment #[slot("footer")]>` fills one slot with two nodes. That call goes through `frame.bpp`, which passes its own footer on with `<Slot name="footer" #[slot("footer")] />` inside its `<Panel>`, so `one` and `two` land in the panel's footer.

`Slot` and `slot` are `rakun-bpp` functions taking `comptime` arguments, run when `html` expands and recording typed meta. The compiler knows no slot. Writing `#[slot("foter")]` would fail the build with an error naming the panel's slots, `default` and `footer`. Lowercase `<slot>` stays the native HTML element.

A draft carries no manifest and no dependency, so the `"bpp": "rakun-bpp"` key is what the promoted cell's `botopink.json` will add.

Cells in this repository that also bear on it: none.

[draft/main.bp](draft/main.bp)

[draft/panel.bpp](draft/panel.bpp)

[draft/frame.bpp](draft/frame.bpp)
