-module(bp_load_cases_fn_expr_typed_in_record_field@main@@Op).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, run) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Op", [{"name", erlang:element(2, V)}, {"run", erlang:element(3, V)}]}.
