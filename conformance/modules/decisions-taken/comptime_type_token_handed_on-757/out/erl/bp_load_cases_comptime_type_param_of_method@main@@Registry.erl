-module(bp_load_cases_comptime_type_param_of_method@main@@Registry).
-export([times/2, count__Users/1, count__Orders/1, weighted__Users/2, weighted__Orders/2, '__bp_get'/2, '__bp_format'/1]).

times(Self, N) ->
    bp_load_cases_comptime_type_param_of_method@main:scaled(N, erlang:length(erlang:element(2, Self))).

count__Users(Self) ->
    K = 0,
    K@4 = lists:foldl(fun(E, K@1) ->
        K@3 = case ((erlang:is_tuple(E) andalso (erlang:tuple_size(E) =:= 2)) andalso (erlang:element(1, E) =:= bp_load_cases_comptime_type_param_of_method@main@@Users)) of
            true ->
                K@2 = '__bp_int'((K@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:24:31">>),
                K@2;
            _ ->
                K@1
        end,
        K@3
    end, K, erlang:element(2, Self)),
    K@4.

count__Orders(Self) ->
    K = 0,
    K@4 = lists:foldl(fun(E, K@1) ->
        K@3 = case ((erlang:is_tuple(E) andalso (erlang:tuple_size(E) =:= 2)) andalso (erlang:element(1, E) =:= bp_load_cases_comptime_type_param_of_method@main@@Orders)) of
            true ->
                K@2 = '__bp_int'((K@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:24:31">>),
                K@2;
            _ ->
                K@1
        end,
        K@3
    end, K, erlang:element(2, Self)),
    K@4.

weighted__Users(Self, W) ->
    bp_load_cases_comptime_type_param_of_method@main:scaled(W, count__Users(Self)).

weighted__Orders(Self, W) ->
    bp_load_cases_comptime_type_param_of_method@main:scaled(W, count__Orders(Self)).

'__bp_get'(V, entries) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Registry", [{"entries", erlang:element(2, V)}]}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
