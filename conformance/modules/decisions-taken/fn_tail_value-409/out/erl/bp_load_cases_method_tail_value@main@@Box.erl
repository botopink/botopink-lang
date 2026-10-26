-module(bp_load_cases_method_tail_value@main@@Box).
-compile({no_auto_import,[get/1]}).
-export([get/1, '__bp_get'/2, '__bp_format'/1]).

get(Self) ->
    erlang:element(2, Self).

'__bp_get'(V, value) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Box", [{"value", erlang:element(2, V)}]}.
