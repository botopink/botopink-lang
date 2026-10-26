-module(bp_load_cases_comptime_type_token_handed_on@main@@Registry).
-export([count__Users/1, count__Orders/1, get__Users/1, get__Orders/1, '__bp_get'/2, '__bp_format'/1]).

count__Users(Self) ->
    N = 0,
    N@4 = lists:foldl(fun(E, N@1) ->
        N@3 = case ((erlang:is_tuple(E) andalso (erlang:tuple_size(E) =:= 2)) andalso (erlang:element(1, E) =:= bp_load_cases_comptime_type_token_handed_on@main@@Users)) of
            true ->
                N@2 = '__bp_int'((N@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:17:31">>),
                N@2;
            _ ->
                N@1
        end,
        N@3
    end, N, erlang:element(2, Self)),
    N@4.

count__Orders(Self) ->
    N = 0,
    N@4 = lists:foldl(fun(E, N@1) ->
        N@3 = case ((erlang:is_tuple(E) andalso (erlang:tuple_size(E) =:= 2)) andalso (erlang:element(1, E) =:= bp_load_cases_comptime_type_token_handed_on@main@@Orders)) of
            true ->
                N@2 = '__bp_int'((N@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:17:31">>),
                N@2;
            _ ->
                N@1
        end,
        N@3
    end, N, erlang:element(2, Self)),
    N@4.

get__Users(Self) ->
    try
        case (count__Users(Self) =:= 0) of
            true ->
                undefined;
            _ ->
                lists:foreach(fun(E) ->
                    case ((erlang:is_tuple(E) andalso (erlang:tuple_size(E) =:= 2)) andalso (erlang:element(1, E) =:= bp_load_cases_comptime_type_token_handed_on@main@@Users)) of
                        true ->
                            erlang:throw({'__bp_try', E});
                        _ -> ok
                    end
                end, erlang:element(2, Self)),
                undefined
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

get__Orders(Self) ->
    try
        case (count__Orders(Self) =:= 0) of
            true ->
                undefined;
            _ ->
                lists:foreach(fun(E) ->
                    case ((erlang:is_tuple(E) andalso (erlang:tuple_size(E) =:= 2)) andalso (erlang:element(1, E) =:= bp_load_cases_comptime_type_token_handed_on@main@@Orders)) of
                        true ->
                            erlang:throw({'__bp_try', E});
                        _ -> ok
                    end
                end, erlang:element(2, Self)),
                undefined
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

'__bp_get'(V, entries) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Registry", [{"entries", erlang:element(2, V)}]}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
