-module(bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box).
-export([optional/1, array/1, '__bp_get'/2, '__bp_format'/1]).

optional(Self) ->
    Inner = erlang:element(2, Self),
    {bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box, fun(At) ->
        bp_load_cases_generic_ctor_fallible_lambda_fresh@main:optionalOf(At, Inner)
    end}.

array(Self) ->
    Inner = erlang:element(2, Self),
    {bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box, fun(At) ->
        bp_load_cases_generic_ctor_fallible_lambda_fresh@main:arrayOf(At, Inner)
    end}.

'__bp_get'(V, run) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Box", [{"run", erlang:element(2, V)}]}.
