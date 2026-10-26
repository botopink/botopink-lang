-module(bp_load_cases_optional_chain_field_after_call@main@@Point).
-export([me/1, '__bp_get'/2, '__bp_format'/1]).

me(Self) ->
    Self.

'__bp_get'(V, x) -> erlang:element(2, V);
'__bp_get'(V, name) -> erlang:element(3, V);
'__bp_get'(V, inner) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Point", [{"x", erlang:element(2, V)}, {"name", erlang:element(3, V)}, {"inner", erlang:element(4, V)}]}.
