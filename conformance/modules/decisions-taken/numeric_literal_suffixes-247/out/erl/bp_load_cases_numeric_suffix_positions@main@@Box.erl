-module(bp_load_cases_numeric_suffix_positions@main@@Box).
-export([grow/2, make/1, '__bp_get'/2, '__bp_format'/1]).

grow(Self, By) ->
    '__bp_int'((erlang:element(3, Self) + By), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/main.bp:33:26">>).

make(Base) ->
    Base.

'__bp_get'(V, label) -> erlang:element(2, V);
'__bp_get'(V, size) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Box", [{"label", erlang:element(2, V)}, {"size", erlang:element(3, V)}]}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
