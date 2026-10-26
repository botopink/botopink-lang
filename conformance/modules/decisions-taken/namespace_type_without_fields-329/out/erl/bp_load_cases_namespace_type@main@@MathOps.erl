-module(bp_load_cases_namespace_type@main@@MathOps).
-export([double/1, first/2, quadruple/1, '__bp_format'/1]).

double(X) ->
    '__bp_int'((X * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:9:18">>).

first(Xs, Fallback) ->
    case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 0) of
        undefined ->
            Fallback;
        __bp_nullish ->
            __bp_nullish
    end.

quadruple(N) ->
    double(double(N)).

'__bp_format'(_) -> {record, "MathOps", []}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
