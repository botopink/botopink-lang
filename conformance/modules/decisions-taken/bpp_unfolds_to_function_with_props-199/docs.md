# Decision 199 — `type Props(…)` in the header is the convention (Astro's `interface Props`).

The example's `card.bpp` declares `pub type Props(title: string, tags: string[] = [])` in its header, so the file unfolds to `pub default fn (props: Props)`. The header's declarations stay at module level: `Props`, and the helper `initial`, which `main` calls as `Card.initial("botopink")` and which prints `B`. The header's statements, `heading` and `count`, become the function's body ahead of the markup, which is why they can read `props.title` and `props.tags`.

`main` imports the module as `Card`. Written as a value or a tag, the module stands for its default function. `<Card title="botopink" tags={["lang", "beam"]}>` passes its attributes as the fields of `Props`, and the `<em>new</em>` inside reaches the card through its default slot (`<Slot />`), never through a field. The first line renders the article with `BOTOPINK`, `2 tags` and the emphasis. `footer.bpp` declares no `Props`, so it unfolds to `pub default fn ()`: `<Footer/>` takes no attribute, and its one statement, `year`, still runs before its markup.

A `.bpp` file is unfolded onto the package that the manifest's `"bpp"` key names. Here that is `rakun-bpp`'s `#[bpp.html]` function, and a draft carries no manifest and no dependency.

Cells in this repository that also bear on it: `modules/bpp_unfold_props`, `modules/bpp_unfold_without_props`, `modules/bpp_declaration_after_statement`.

[draft/main.bp](draft/main.bp)

[draft/card.bpp](draft/card.bpp)

[draft/footer.bpp](draft/footer.bpp)
