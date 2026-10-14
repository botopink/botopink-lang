# template_hole_prints_every_value

The reference text this cell shows (from `conformance/docs.md`, § Literals):

> A template hole writes the text `@print` writes for every value (decision 530) — a record
> `Point(x: 1, y: 2)`, an array `[1, 2, 3]`, a tuple `#(1, "a")`, `null`, an enum — on every target, and
> a `string` writes itself. A type implementing `Display` writes its `display()` in a hole as in `@print`.
> A `Bytes` hole stays refused. Each hole below is printed beside the `@print` of the same value:
