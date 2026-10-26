-module(bp_load_cases_sibling_blocks_bind_one_name@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({bp_load_cases_sibling_blocks_bind_one_name@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"radius", F0}]};
'__bp_format'({bp_load_cases_sibling_blocks_bind_one_name@main@@Shape__v__square, F0}) -> {variant, "Shape.Square", [{"side", F0}]}.
