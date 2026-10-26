-module(bp_load_cases_optional_enum_method_call@main@@Val).
-export([str/1, plus/2, '__bp_format'/1]).

str(Self) ->
    case Self of
        {bp_load_cases_optional_enum_method_call@main@@Val__v__text, T} ->
            T;
        _ ->
            <<"">>
    end.

plus(Self, K) ->
    case Self of
        {bp_load_cases_optional_enum_method_call@main@@Val__v__num, V} ->
            '__bp_int'((V + K), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:23:28">>);
        _ ->
            K
    end.

'__bp_format'({bp_load_cases_optional_enum_method_call@main@@Val__v__num, F0}) -> {variant, "Val.Num", [{"n", F0}]};
'__bp_format'({bp_load_cases_optional_enum_method_call@main@@Val__v__text, F0}) -> {variant, "Val.Text", [{"s", F0}]}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
