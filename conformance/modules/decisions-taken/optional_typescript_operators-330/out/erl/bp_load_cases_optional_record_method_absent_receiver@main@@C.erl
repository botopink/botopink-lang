-module(bp_load_cases_optional_record_method_absent_receiver@main@@C).
-export([n/1, '__bp_format'/1]).

n(Self) ->
    case Self of
        bp_load_cases_optional_record_method_absent_receiver@main@@C__v__red ->
            0;
        bp_load_cases_optional_record_method_absent_receiver@main@@C__v__green ->
            1
    end.

'__bp_format'(bp_load_cases_optional_record_method_absent_receiver@main@@C__v__red) -> {variant, "C.Red", []};
'__bp_format'(bp_load_cases_optional_record_method_absent_receiver@main@@C__v__green) -> {variant, "C.Green", []}.
