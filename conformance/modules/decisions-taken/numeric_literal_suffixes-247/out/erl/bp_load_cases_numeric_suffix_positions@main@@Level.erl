-module(bp_load_cases_numeric_suffix_positions@main@@Level).
-export([weight/2, '__bp_format'/1]).

weight(Self, K) ->
    K.

'__bp_format'(bp_load_cases_numeric_suffix_positions@main@@Level__v__low) -> {variant, "Level.Low", []};
'__bp_format'(bp_load_cases_numeric_suffix_positions@main@@Level__v__high) -> {variant, "Level.High", []}.
