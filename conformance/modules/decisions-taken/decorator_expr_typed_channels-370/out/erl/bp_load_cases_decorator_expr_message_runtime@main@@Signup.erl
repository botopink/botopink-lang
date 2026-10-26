-module(bp_load_cases_decorator_expr_message_runtime@main@@Signup).
-export([validate/1, '__bp_get'/2, '__bp_format'/1]).

validate(Self) ->
    case bp_load_cases_decorator_expr_message_runtime@main:passwordsMatch(Self) of
        true ->
            [];
        _ ->
            [{bp_load_cases_decorator_expr_message_runtime@main@@Violation, <<"confirm">>, (bp_load_cases_decorator_expr_message_runtime@main:t(<<"signup.mismatch">>))}]
    end.

'__bp_get'(V, password) -> erlang:element(2, V);
'__bp_get'(V, confirm) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Signup", [{"password", erlang:element(2, V)}, {"confirm", erlang:element(3, V)}]}.
