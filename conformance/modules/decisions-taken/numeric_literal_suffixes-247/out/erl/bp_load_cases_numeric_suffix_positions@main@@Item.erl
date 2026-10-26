-module(bp_load_cases_numeric_suffix_positions@main@@Item).
-export([tag/2, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

tag(Self, N) ->
    '__bp_int'((erlang:element(2, Self) + N), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/main.bp:53:24">>).

'__bp_get'(V, id) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Item", [{"id", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [bp_load_cases_numeric_suffix_positions@main@@Tag].

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
