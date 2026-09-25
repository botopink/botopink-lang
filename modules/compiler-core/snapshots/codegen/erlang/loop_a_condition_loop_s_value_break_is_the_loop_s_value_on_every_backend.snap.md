----- SOURCE CODE -- main.bp
```botopink
fn main() {
    var i = 0;
    val found = while (i < 10) { if (i == 4) { break i * 2; }; i = i + 1; };
    @print(found);
    @print(i);
    var k = 0;
    val r = loop { k = k + 1; if (k > 2) { break k; }; };
    @print(r);
    var n = 0;
    val never = while (n < 3) { if (n == 99) { break n; }; n = n + 1; };
    @print(never);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    I = 0,
    Found = case try
        {(fun __Loop(I@1) ->
            case (I@1 < 10) of
                true ->
                    case (I@1 =:= 4) of
                        true ->
                            erlang:throw({'__bp_cond_break', I@1, (I@1 * 2)});
                        _ -> ok
                    end,
                    I@2 = (I@1 + 1),
                    __Loop(I@2);
                _ -> I@1
            end
        end)(I), undefined}
    catch
        throw:{'__bp_cond_break', __BpGroup1, __BpBreak1} -> {__BpGroup1, __BpBreak1}
    end of
        {I@3, __BpValue1} -> __BpValue1
    end,
    '__bp_print'([Found]),
    '__bp_print'([I@3]),
    K = 0,
    R = case try
        {(fun __Loop(K@1) ->
            case true of
                true ->
                    K@2 = (K@1 + 1),
                    case (K@2 > 2) of
                        true ->
                            erlang:throw({'__bp_cond_break', K@2, K@2});
                        _ -> ok
                    end,
                    __Loop(K@2);
                _ -> K@1
            end
        end)(K), undefined}
    catch
        throw:{'__bp_cond_break', __BpGroup2, __BpBreak2} -> {__BpGroup2, __BpBreak2}
    end of
        {K@3, __BpValue2} -> __BpValue2
    end,
    '__bp_print'([R]),
    N = 0,
    Never = case try
        {(fun __Loop(N@1) ->
            case (N@1 < 3) of
                true ->
                    case (N@1 =:= 99) of
                        true ->
                            erlang:throw({'__bp_cond_break', N@1, N@1});
                        _ -> ok
                    end,
                    N@2 = (N@1 + 1),
                    __Loop(N@2);
                _ -> N@1
            end
        end)(N), undefined}
    catch
        throw:{'__bp_cond_break', __BpGroup3, __BpBreak3} -> {__BpGroup3, __BpBreak3}
    end of
        {N@3, __BpValue3} -> __BpValue3
    end,
    '__bp_print'([Never]).

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
undefined
```
