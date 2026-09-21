----- SOURCE CODE -- main.bp
```botopink
fn lookup(pairs: Array<#(string, i32)>, key: string) -> ?i32 {
    return pairs.find({ pair -> pair.0 == key }).map({ pair -> pair.1 });
}

fn main() {
    val pairs = [#("a", 1), #("b", 2)];
    @print(lookup(pairs, "b"));
    @print(lookup(pairs, "z") == null);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% behavior Array

array_range(Start, Stop) ->
    case (Start >= Stop) of
        true ->
            [];
        false ->
            Head = Start,
            [Head] ++ (array_range((Start + 1), Stop))
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Head = Value,
            [Head] ++ (array_repeat(Value, (Times - 1)))
    end.

lookup(Pairs, Key) ->
    (fun(O) -> case O of undefined -> undefined; V -> (fun(Pair) ->
        element(2, Pair)
    end)(V) end end)(array_find(Pairs, fun(Pair) ->
        (element(1, Pair) =:= Key)
    end)).

main() ->
    Pairs = [{<<"a">>, 1}, {<<"b">>, 2}],
    '__bp_print'([lookup(Pairs, <<"b">>)]),
    '__bp_print'([(lookup(Pairs, <<"z">>) =:= undefined)]).

array_find(Self, Pred) ->
    (fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(lists:filter(Pred, Self), 0).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
2
true
```
