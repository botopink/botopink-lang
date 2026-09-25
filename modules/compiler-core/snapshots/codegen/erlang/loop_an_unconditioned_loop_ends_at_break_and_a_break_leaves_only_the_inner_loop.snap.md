----- SOURCE CODE -- main.bp
```botopink
fn firstSquareOver(n: i32) -> i32 {
    var k = 0;
    loop {
        k = k + 1;
        if (k * k > n) { break; };
    };
    return k;
}
fn nested() -> i32 {
    var outer = 0;
    var inner = 0;
    while (outer < 3) {
        outer = outer + 1;
        loop {
            inner = inner + 1;
            break;
        };
    };
    return outer * 10 + inner;
}
fn main() {
    @print(firstSquareOver(20));
    @print(nested());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

firstSquareOver(N) ->
    K = 0,
    K@3 = try
        (fun __Loop(K@1) ->
            K@2 = (K@1 + 1),
            case ((K@2 * K@2) > N) of
                true ->
                    erlang:throw({'__bp_cond_break', K@2});
                _ -> ok
            end,
            __Loop(K@2)
        end)(K)
    catch
        throw:{'__bp_cond_break', __BpGroup1} -> __BpGroup1
    end,
    K@3.

nested() ->
    Outer = 0,
    Inner = 0,
    {Outer@3, Inner@5} = (fun __Loop({Outer@1, Inner@1}) ->
        case (Outer@1 < 3) of
            true ->
                Outer@2 = (Outer@1 + 1),
                Inner@4 = try
                    (fun __Loop1(Inner@2) ->
                        Inner@3 = (Inner@2 + 1),
                        erlang:throw({'__bp_cond_break', Inner@3}),
                        __Loop1(Inner@3)
                    end)(Inner@1)
                catch
                    throw:{'__bp_cond_break', __BpGroup3} -> __BpGroup3
                end,
                __Loop({Outer@2, Inner@4});
            _ -> {Outer@1, Inner@1}
        end
    end)({Outer, Inner}),
    ((Outer@3 * 10) + Inner@5).

main() ->
    '__bp_print'([firstSquareOver(20)]),
    '__bp_print'([nested()]).

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
5
33
```
