-module(std@collections@@Dict).
-compile({no_auto_import,[size/1]}).
-export([display/1, at/2, hasKey/2, size/1, isEmpty/1, keys/1, values/1, insert/3, bump/3, delete/2, merge/2, fold/3, mapValues/2, empty/0, ofEntries/1, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

display(Self) ->
    Parts = [],
    Parts@3 = lists:foldl(fun(P, Parts@1) ->
        Parts@2 = (Parts@1 ++ [<<(std@collections:shown(erlang:element(1, P)))/binary, ": ", (std@collections:shown(erlang:element(2, P)))/binary>>]),
        Parts@2
    end, Parts, erlang:element(2, Self)),
    <<"Dict(", ('__bp_text'(iolist_to_binary(lists:join(<<", ">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Parts@3)))))/binary, ")">>.

at(Self, Key) ->
    % NOTE: written with `forEach` + accumulator rather than
    % `.at(0).map(…)` — chained method dispatch on a `?T` (option-map) is
    % not lowered yet (tracked in tasks/v0.beta.4 Part A: primitive/option
    % method dispatch). `.at(0)` here would type as array, not `?T`.
    Found = lists:foldl(fun(P, Found) ->
        case (erlang:element(1, P) =:= Key) of
            true -> erlang:element(2, P);
            _ -> Found
        end
    end, undefined, erlang:element(2, Self)),
    Found.

hasKey(Self, Key) ->
    ((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(lists:filter(fun(P) ->
        (erlang:element(1, P) =:= Key)
    end, erlang:element(2, Self)), 0) =/= undefined).

size(Self) ->
    erlang:length(erlang:element(2, Self)).

isEmpty(Self) ->
    (erlang:length(erlang:element(2, Self)) =:= 0).

keys(Self) ->
    lists:map(fun(P) ->
        erlang:element(1, P)
    end, erlang:element(2, Self)).

values(Self) ->
    lists:map(fun(P) ->
        erlang:element(2, P)
    end, erlang:element(2, Self)).

insert(Self, Key, Value) ->
    Filtered = lists:filter(fun(P) ->
        (erlang:element(1, P) =/= Key)
    end, erlang:element(2, Self)),
    {std@collections@@Dict, (Filtered ++ [{Key, Value}])}.

bump(Self, Key, By) ->
    insert(Self, Key, '__bp_add'((case at(Self, Key) of
        undefined ->
            0;
        __bp_nullish ->
            __bp_nullish
    end), By)).

delete(Self, Key) ->
    {std@collections@@Dict, lists:filter(fun(P) ->
        (erlang:element(1, P) =/= Key)
    end, erlang:element(2, Self))}.

merge(Self, Other) ->
    Out = lists:foldl(fun(P, Out) ->
        insert(Out, erlang:element(1, P), erlang:element(2, P))
    end, Self, erlang:element(2, Other)),
    Out.

fold(Self, Initial, F) ->
    Acc = lists:foldl(fun(P, Acc) ->
        F(Acc, erlang:element(1, P), erlang:element(2, P))
    end, Initial, erlang:element(2, Self)),
    Acc.

mapValues(Self, F) ->
    Out = lists:foldl(fun(P, Out) ->
        (Out ++ [{erlang:element(1, P), F(erlang:element(2, P))}])
    end, [], erlang:element(2, Self)),
    {std@collections@@Dict, Out}.

empty() ->
    {std@collections@@Dict, []}.

ofEntries(Entries) ->
    Out = lists:foldl(fun(E, Out) ->
        insert(Out, erlang:element(1, E), erlang:element(2, E))
    end, {std@collections@@Dict, []}, Entries),
    Out.

'__bp_get'(V, pairs) -> erlang:element(2, V).

'__bp_format'(V) -> {text, display(V)}.

'__bp_behaviors'() -> [std@primitives@@Index, std@primitives@@Display].

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].
