-module(bp_load_cases_external_library_source_beside_member@main@@Box).
-export([tag/1, '__bp_get'/2, '__bp_format'/1]).

tag(Self) ->
    <<"tagged">>.

'__bp_get'(V, size) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Box", [{"size", erlang:element(2, V)}]}.
