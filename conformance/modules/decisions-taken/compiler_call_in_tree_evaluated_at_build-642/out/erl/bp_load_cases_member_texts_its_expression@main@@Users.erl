-module(bp_load_cases_member_texts_its_expression@main@@Users).
-export([spell/1, '__bp_get'/2, '__bp_format'/1]).

spell(X) ->
    <<"x + 1">>.

'__bp_get'(V, id) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Users", [{"id", erlang:element(2, V)}]}.
