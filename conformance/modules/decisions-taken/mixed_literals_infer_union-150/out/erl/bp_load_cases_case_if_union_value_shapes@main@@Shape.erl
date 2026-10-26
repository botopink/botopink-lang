-module(bp_load_cases_case_if_union_value_shapes@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"r", F0}]};
'__bp_format'({bp_load_cases_case_if_union_value_shapes@main@@Shape__v__label, F0}) -> {variant, "Shape.Label", [{"text", F0}]}.
