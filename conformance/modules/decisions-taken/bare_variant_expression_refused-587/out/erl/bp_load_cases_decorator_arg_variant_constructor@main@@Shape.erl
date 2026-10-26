-module(bp_load_cases_decorator_arg_variant_constructor@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'({bp_load_cases_decorator_arg_variant_constructor@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"radius", F0}]};
'__bp_format'(bp_load_cases_decorator_arg_variant_constructor@main@@Shape__v__dot) -> {variant, "Shape.Dot", []}.
