-module(bp_load_cases_fn_defaults_values@main@@P).
-export([bump/2, '__bp_get'/2, '__bp_format'/1]).

bump(Self, By) ->
    '__bp_int'((erlang:element(2, Self) + By), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:19:23">>).

'__bp_get'(V, y) -> erlang:element(2, V);
'__bp_get'(V, x) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "P", [{"y", erlang:element(2, V)}, {"x", erlang:element(3, V)}]}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
