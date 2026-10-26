-module(bp_load_cases_optional_index_record_field@main@@Field).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, message) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Field", [{"name", erlang:element(2, V)}, {"message", erlang:element(3, V)}]}.
