-module(bp_load_cases_member_reads_own_meta@main@@Conta).
-export([validate/1, '__bp_get'/2, '__bp_format'/1]).

validate(Self) ->
    Out = [],
    Out@4 = lists:foldl(fun(C, Out@1) ->
        Out@3 = case (not (erlang:element(3, C))(Self)) of
            true ->
                Out@2 = (Out@1 ++ [{bp_load_cases_member_reads_own_meta@main@@Violation, <<"conta">>, erlang:element(2, C)}]),
                Out@2;
            _ ->
                Out@1
        end,
        Out@3
    end, Out, [{bp_load_cases_member_reads_own_meta@main@@Check, <<"the passwords differ">>, fun(__BpA0) -> bp_load_cases_member_reads_own_meta@main:passwordsMatch(__BpA0) end}, {bp_load_cases_member_reads_own_meta@main@@Check, <<"the handle is taken">>, fun(__BpA0) -> bp_load_cases_member_reads_own_meta@main:handleFree(__BpA0) end}]),
    Out@4.

'__bp_get'(V, handle) -> erlang:element(2, V);
'__bp_get'(V, password) -> erlang:element(3, V);
'__bp_get'(V, confirm) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Conta", [{"handle", erlang:element(2, V)}, {"password", erlang:element(3, V)}, {"confirm", erlang:element(4, V)}]}.
