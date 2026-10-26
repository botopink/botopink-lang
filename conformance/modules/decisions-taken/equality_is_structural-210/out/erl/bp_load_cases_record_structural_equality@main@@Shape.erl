-module(bp_load_cases_record_structural_equality@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({bp_load_cases_record_structural_equality@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"r", F0}]};
'__bp_format'({bp_load_cases_record_structural_equality@main@@Shape__v__rect, F0, F1}) -> {variant, "Shape.Rect", [{"w", F0}, {"h", F1}]};
'__bp_format'(bp_load_cases_record_structural_equality@main@@Shape__v__dot) -> {variant, "Shape.Dot", []}.
