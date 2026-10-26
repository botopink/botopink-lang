-module(bp_load_cases_ast_fn_node_builds_mock_member@main@@Greeter).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, id) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Greeter", [{"id", erlang:element(2, V)}]}.
