-module(bp_load_cases_enum_variant_labelled_reorder@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({bp_load_cases_enum_variant_labelled_reorder@main@@Shape__v__circle, F0, F1, F2}) -> {variant, "Shape.Circle", [{"radius", F0}, {"filled", F1}, {"name", F2}]};
'__bp_format'({bp_load_cases_enum_variant_labelled_reorder@main@@Shape__v__rect, F0, F1}) -> {variant, "Shape.Rect", [{"width", F0}, {"height", F1}]}.
