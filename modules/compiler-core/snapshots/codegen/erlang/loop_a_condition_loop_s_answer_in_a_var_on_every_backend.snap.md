----- SOURCE CODE -- main.bp
```botopink
fn main() {
    var i = 0;
    var found = 0;
    while (i < 10) { if (i == 4) { found = i * 2; break; }; i = i + 1; };
    @print(found);
    @print(i);
    var k = 0;
    var r = 0;
    loop { k = k + 1; if (k > 2) { r = k; break; }; };
    @print(r);
    var n = 0;
    var never = 0;
    while (n < 3) { if (n == 99) { never = n; break; }; n = n + 1; };
    @print(never);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

main() ->
    I = 0,
    Found = 0,
    {Found@4, I@3} = try
        (fun __Loop({Found@1, I@1}) ->
            case (I@1 < 10) of
                true ->
                    Found@3 = case (I@1 =:= 4) of
                        true ->
                            Found@2 = (I@1 * 2),
                            erlang:throw({'__bp_cond_break', {Found@2, I@1}}),
                            Found@2;
                        _ ->
                            Found@1
                    end,
                    I@2 = (I@1 + 1),
                    __Loop({Found@3, I@2});
                _ -> {Found@1, I@1}
            end
        end)({Found, I})
    catch
        throw:{'__bp_cond_break', __BpGroup1} -> __BpGroup1
    end,
    '__bp_print'([Found@4]),
    '__bp_print'([I@3]),
    K = 0,
    R = 0,
    {K@3, R@4} = try
        (fun __Loop({K@1, R@1}) ->
            K@2 = (K@1 + 1),
            R@3 = case (K@2 > 2) of
                true ->
                    R@2 = K@2,
                    erlang:throw({'__bp_cond_break', {K@2, R@2}}),
                    R@2;
                _ ->
                    R@1
            end,
            __Loop({K@2, R@3})
        end)({K, R})
    catch
        throw:{'__bp_cond_break', __BpGroup2} -> __BpGroup2
    end,
    '__bp_print'([R@4]),
    N = 0,
    Never = 0,
    {Never@4, N@3} = try
        (fun __Loop({Never@1, N@1}) ->
            case (N@1 < 3) of
                true ->
                    Never@3 = case (N@1 =:= 99) of
                        true ->
                            Never@2 = N@1,
                            erlang:throw({'__bp_cond_break', {Never@2, N@1}}),
                            Never@2;
                        _ ->
                            Never@1
                    end,
                    N@2 = (N@1 + 1),
                    __Loop({Never@3, N@2});
                _ -> {Never@1, N@1}
            end
        end)({Never, N})
    catch
        throw:{'__bp_cond_break', __BpGroup3} -> __BpGroup3
    end,
    '__bp_print'([Never@4]).

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
8
4
3
0
```
