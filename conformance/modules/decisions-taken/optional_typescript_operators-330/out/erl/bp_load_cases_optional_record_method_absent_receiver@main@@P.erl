-module(bp_load_cases_optional_record_method_absent_receiver@main@@P).
-export([twice/1, half/1, zero/1, 'maybe'/1, me/1, '__bp_get'/2, '__bp_format'/1]).

twice(Self) ->
    '__bp_int'((erlang:element(2, Self) * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:13:23">>).

half(Self) ->
    1.5.

zero(Self) ->
    (erlang:element(2, Self) =:= 0).

'maybe'(Self) ->
    case (erlang:element(2, Self) =:= 0) of
        true ->
            0;
        false ->
            undefined
    end.

me(Self) ->
    {bp_load_cases_optional_record_method_absent_receiver@main@@P, '__bp_int'((erlang:element(2, Self) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:25:28">>)}.

'__bp_get'(V, x) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "P", [{"x", erlang:element(2, V)}]}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
