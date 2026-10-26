-module(bp_load_cases_equality_rule_by_value@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({bp_load_cases_equality_rule_by_value@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"radius", F0}]};
'__bp_format'({bp_load_cases_equality_rule_by_value@main@@Shape__v__square, F0}) -> {variant, "Shape.Square", [{"side", F0}]}.
