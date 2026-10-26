-module(bp_load_cases_trailing_lambda_call@main@@Box).
-export([run/2, through/2, add/3, '__bp_get'/2, '__bp_format'/1]).

run(Self, F) ->
    '__bp_add'(erlang:element(2, Self), F()).

through(Self, F) ->
    F(erlang:element(2, Self)).

add(Self, N, F) ->
    '__bp_int'((N + F()), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:15:18">>).

'__bp_get'(V, base) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Box", [{"base", erlang:element(2, V)}]}.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
