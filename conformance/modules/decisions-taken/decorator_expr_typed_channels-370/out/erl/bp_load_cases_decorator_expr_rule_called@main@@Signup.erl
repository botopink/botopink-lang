-module(bp_load_cases_decorator_expr_rule_called@main@@Signup).
-export([validate/1, '__bp_get'/2, '__bp_format'/1]).

validate(Self) ->
    case bp_load_cases_decorator_expr_rule_called@main:passwordsMatch(Self) of
        true ->
            [];
        _ ->
            [{bp_load_cases_decorator_expr_rule_called@main@@Violation, <<"confirm">>, (<<"the passwords differ">>)}]
    end.

'__bp_get'(V, password) -> erlang:element(2, V);
'__bp_get'(V, confirm) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Signup", [{"password", erlang:element(2, V)}, {"confirm", erlang:element(3, V)}]}.
