----- SOURCE CODE -- main.bp
```botopink
fn find(arr: i32[]) -> i32 {
    var found = 0;
    for (arr) { x ->
        if (x > 10) { found = x; break; };
    };
    return found;
}
fn main() {
    @print(find([5, 8, 15, 20]));
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

find(Arr) ->
    Found = 0,
    Found@4 = try
        (fun __Loop(__BpIter1, Found@1) ->
            case __BpIter1 of
                [X | __BpRest1] ->
                    Found@3 = case (X > 10) of
                        true ->
                            Found@2 = X,
                            erlang:throw({'__bp_cond_break', Found@2}),
                            Found@2;
                        _ ->
                            Found@1
                    end,
                    __Loop(__BpRest1, Found@3);
                _ -> Found@1
            end
        end)(Arr, Found)
    catch
        throw:{'__bp_cond_break', __BpGroup1} -> __BpGroup1
    end,
    Found@4.

main() ->
    '__bp_print'([find([5, 8, 15, 20])]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
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
15
```
