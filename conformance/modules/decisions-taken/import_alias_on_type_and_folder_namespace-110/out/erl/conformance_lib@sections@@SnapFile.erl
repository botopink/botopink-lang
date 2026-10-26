-module(conformance_lib@sections@@SnapFile).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, sections) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "SnapFile", [{"sections", erlang:element(2, V)}]}.
