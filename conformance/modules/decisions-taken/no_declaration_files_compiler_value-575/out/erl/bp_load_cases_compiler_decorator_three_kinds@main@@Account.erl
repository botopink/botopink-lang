-module(bp_load_cases_compiler_decorator_three_kinds@main@@Account).
-export([validate/1, '__bp_get'/2, '__bp_format'/1]).

validate(Self) ->
    case bp_load_cases_compiler_decorator_three_kinds@main:positive(Self) of
        true ->
            [];
        _ ->
            [{bp_load_cases_compiler_decorator_three_kinds@main@@Violation, (<<"negative balance">>)}, {bp_load_cases_compiler_decorator_three_kinds@main@@Violation, (<<"negative balance (positive)">>)}]
    end.

'__bp_get'(V, balance) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Account", [{"balance", erlang:element(2, V)}]}.
