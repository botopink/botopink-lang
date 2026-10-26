-module(bp_load_cases_member_reads_compiler_name@main@@Users).
-export([label/0, '__bp_get'/2, '__bp_format'/1]).

label() ->
    (<<"Users">>).

'__bp_get'(V, id) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Users", [{"id", erlang:element(2, V)}]}.
