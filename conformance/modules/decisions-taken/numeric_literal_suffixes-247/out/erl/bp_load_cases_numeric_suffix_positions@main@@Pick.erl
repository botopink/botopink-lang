-module(bp_load_cases_numeric_suffix_positions@main@@Pick).
-export(['band'/1, '__bp_get'/2, '__bp_format'/1]).

'band'(Self) ->
    case erlang:element(2, Self) of
        V when (V > 5) ->
            <<"high">>;
        _ ->
            <<"low">>
    end.

'__bp_get'(V, n) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Pick", [{"n", erlang:element(2, V)}]}.
