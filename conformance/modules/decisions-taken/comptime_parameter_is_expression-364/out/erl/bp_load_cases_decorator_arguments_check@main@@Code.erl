-module(bp_load_cases_decorator_arguments_check@main@@Code).
-export(['__bp_format'/1]).

'__bp_format'(bp_load_cases_decorator_arguments_check@main@@Code__v__custom) -> {variant, "Code.Custom", []};
'__bp_format'(bp_load_cases_decorator_arguments_check@main@@Code__v__required) -> {variant, "Code.Required", []};
'__bp_format'(bp_load_cases_decorator_arguments_check@main@@Code__v__tooshort) -> {variant, "Code.TooShort", []};
'__bp_format'(bp_load_cases_decorator_arguments_check@main@@Code__v__mismatch) -> {variant, "Code.Mismatch", []}.
