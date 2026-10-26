-module(bp_load_cases_context_behavior_implemented_indirectly@main@@CachedRepository).
-export([fetch/2, hits/1, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

fetch(Self, Id) ->
    '__bp_add'(erlang:element(2, Self), erlang:integer_to_binary(Id)).

hits(Self) ->
    3.

'__bp_get'(V, prefix) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "CachedRepository", [{"prefix", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [bp_load_cases_context_behavior_implemented_indirectly@main@@Cached, bp_load_cases_context_behavior_implemented_indirectly@main@@Repository].

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.
