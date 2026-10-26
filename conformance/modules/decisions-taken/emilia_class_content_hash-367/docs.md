# Decision 367 — Contract 4 follows 338: an emilia class is the layer's prefix plus `contentHash` over the class's rules, as `styled` renders them — one class rule for every component.

The example names a style class the way the style library does. The class is the layer's prefix, `e_`, plus std's `hash.contentHash` over the class's rules, as the style library renders them. So one rule text gives one class name for every component and every target: `card` and `sameCard` print the same name. A rule that differs by one declaration gets another name, so `card == other` is `false`. The hash is part of the class rule alone, not of a codec payload. The shared fixture of the decision, `className(cardTokens(), defaultTheme()) == "e_f51c2501"`, is the library's own; this example shows the rule it rests on with std alone.

The program prints the same `e_…` name twice, then `true` and `false`.

Cells in this repository that bear on it: `modules/decisions-taken/content_hash_folds_codepoints-260/cases/std_hash_on_every_target`.

[draft/main.bp](draft/main.bp)
