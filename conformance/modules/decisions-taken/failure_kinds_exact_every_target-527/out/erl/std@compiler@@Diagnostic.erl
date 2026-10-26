-module(std@compiler@@Diagnostic).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, code) -> erlang:element(2, V);
'__bp_get'(V, message) -> erlang:element(3, V);
'__bp_get'(V, file) -> erlang:element(4, V);
'__bp_get'(V, line) -> erlang:element(5, V);
'__bp_get'(V, column) -> erlang:element(6, V);
'__bp_get'(V, label) -> erlang:element(7, V);
'__bp_get'(V, '`from`') -> erlang:element(8, V).

'__bp_format'(V) -> {record, "Diagnostic", [{"code", erlang:element(2, V)}, {"message", erlang:element(3, V)}, {"file", erlang:element(4, V)}, {"line", erlang:element(5, V)}, {"column", erlang:element(6, V)}, {"label", erlang:element(7, V)}, {"`from`", erlang:element(8, V)}]}.
