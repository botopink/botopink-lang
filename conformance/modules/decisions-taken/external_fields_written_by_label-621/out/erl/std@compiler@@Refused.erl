-module(std@compiler@@Refused).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, module) -> erlang:element(2, V);
'__bp_get'(V, diagnostics) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Refused", [{"module", erlang:element(2, V)}, {"diagnostics", erlang:element(3, V)}]}.
