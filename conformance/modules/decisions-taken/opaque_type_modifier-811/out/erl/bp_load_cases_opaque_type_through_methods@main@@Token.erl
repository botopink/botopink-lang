-module(bp_load_cases_opaque_type_through_methods@main@@Token).
-export(['of'/1, bumped/1, used/1, value/1, uses/1, '__bp_get'/2, '__bp_format'/1]).

'of'(Value) ->
    {bp_load_cases_opaque_type_through_methods@main@@Token, Value, 0}.

bumped(T) ->
    {bp_load_cases_opaque_type_through_methods@main@@Token, erlang:element(2, T), '__bp_int'((erlang:element(3, T) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:15:51">>)}.

used(Self) ->
    bumped(Self).

value(Self) ->
    erlang:element(2, Self).

uses(Self) ->
    erlang:element(3, Self).

'__bp_get'(V, value) -> erlang:element(2, V);
'__bp_get'(V, uses) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Token", [{"value", erlang:element(2, V)}, {"uses", erlang:element(3, V)}]}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
