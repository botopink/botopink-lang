----- SOURCE CODE -- main.bp
```botopink
fn pick(xs: Array<string>) -> string {
    var first = "";
    var last = "";
    var i = 0;
    for (xs) { x ->
        if (i == 0) { first = x; };
        last = x;
        i = i + 1;
    };
    return first + "-" + last;
}
fn weigh(xs: Array<i32>) -> i32 {
    var total = 0;
    for (0..xs.length) { i ->
        total = total + (xs[i] ?? 0) * (i + 1);
    };
    return total;
}
fn main() {
    @print(pick(["a", "b", "c"]));
    @print(weigh([10, 20, 30]));
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

pick(Xs) ->
    First = <<"">>,
    Last = <<"">>,
    I = 0,
    {First@4, Last@3, I@3} = lists:foldl(fun(X, {First@1, Last@1, I@1}) ->
        First@3 = case (I@1 =:= 0) of
            true ->
                First@2 = X,
                First@2;
            _ ->
                First@1
        end,
        Last@2 = X,
        I@2 = (I@1 + 1),
        {First@3, Last@2, I@2}
    end, {First, Last, I}, Xs),
    <<First@4/binary, "-", Last@3/binary>>.

weigh(Xs) ->
    Total = 0,
    Total@3 = lists:foldl(fun(I, Total@1) ->
        Total@2 = (Total@1 + ((case '__bp_index'(Xs, I) of
            undefined ->
                0;
            __bp_nullish ->
                __bp_nullish
        end) * ((I + 1)))),
        Total@2
    end, Total, lists:seq(0, (length(Xs)) - 1)),
    Total@3.

main() ->
    '__bp_print'([pick([<<"a">>, <<"b">>, <<"c">>])]),
    '__bp_print'([weigh([10, 20, 30])]).

'__bp_index'(Recv, I) when is_list(Recv), is_integer(I), I >= 0, I < length(Recv) -> lists:nth(I + 1, Recv);
'__bp_index'(Recv, I) when is_list(Recv), is_integer(I), I < 0, I + length(Recv) >= 0 -> lists:nth(I + length(Recv) + 1, Recv);
'__bp_index'(Recv, I) when is_binary(Recv), is_integer(I), I >= 0 -> string:slice(Recv, I, 1);
'__bp_index'(Recv, I) when is_tuple(Recv), is_integer(I), I >= 0, I < tuple_size(Recv) -> element(I + 1, Recv);
'__bp_index'(Recv, I) when is_list(Recv), is_integer(I) -> undefined;
'__bp_index'(Recv, I) when is_tuple(Recv), is_integer(I) -> undefined;
'__bp_index'(Recv, I) -> erlang:error({bp_unsupported_index, Recv, I}).

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
a-c
140
```
