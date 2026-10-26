-module(bp_load_cases_case_multi_subject_patterns@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({bp_load_cases_case_multi_subject_patterns@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"r", F0}]};
'__bp_format'({bp_load_cases_case_multi_subject_patterns@main@@Shape__v__square, F0}) -> {variant, "Shape.Square", [{"side", F0}]};
'__bp_format'(bp_load_cases_case_multi_subject_patterns@main@@Shape__v__empty) -> {variant, "Shape.Empty", []}.
