-module(bp_load_cases_decorator_member_captures@main@@Violation).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, field) -> erlang:element(2, V);
'__bp_get'(V, message) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Violation", [{"field", erlang:element(2, V)}, {"message", erlang:element(3, V)}]}.
