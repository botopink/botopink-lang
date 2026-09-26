----- SOURCE CODE -- main.bp
```botopink
type Box(items: Array<i32>) {
    fn total(self: Self) -> i32 {
        var sum = 0;
        self.items.forEach({ n -> sum = sum + n });
        return sum;
    }
    fn isBig(self: Self) -> bool { return self.items.length > 1; }
    fn doubled(self: Self) -> Array<i32> { return self.items.map({ n -> n * 2 }); }
    fn label(self: Self) -> string { return "box"; }
}
fn main() {
    var seen = 0;
    [1, 2].forEach({ n -> seen = n });
    @print(seen);
    val b = Box(items: [3, 4]);
    @print(b.total());
    var h: ?i32 = null;
    @print(h);
    h = 5;
    @print(h);
    var acc: ?i32 = null;
    [7, 8].forEach({ n -> acc = n });
    @print(acc);
    @print(b.isBig());
    @print(b.doubled());
    @print(b.label());
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% type Box: items

main() ->
    Seen = lists:foldl(fun(N, Seen) ->
        N
    end, 0, [1, 2]),
    '__bp_print'([Seen]),
    B = {test@main@@Box, [3, 4]},
    '__bp_print'([test@main@@Box:total(B)]),
    H = undefined,
    '__bp_print'([H]),
    H@1 = 5,
    '__bp_print'([H@1]),
    Acc = lists:foldl(fun(N, Acc) ->
        N
    end, undefined, [7, 8]),
    '__bp_print'([Acc]),
    '__bp_print'([test@main@@Box:isBig(B)]),
    '__bp_print'([test@main@@Box:doubled(B)]),
    '__bp_print'([test@main@@Box:label(B)]).

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

----- ERLANG -- test@main@@Box.erl
```erlang
-module(test@main@@Box).
-export([total/1, isBig/1, doubled/1, label/1, '__bp_get'/2, '__bp_format'/1]).

total(Self) ->
    Sum = lists:foldl(fun(N, Sum) ->
        '__bp_add'(Sum, N)
    end, 0, element(2, Self)),
    Sum.

isBig(Self) ->
    (erlang:length(element(2, Self)) > 1).

doubled(Self) ->
    lists:map(fun(N) ->
        (N * 2)
    end, element(2, Self)).

label(Self) ->
    <<"box">>.

'__bp_get'(V, items) -> element(2, V).

'__bp_format'(V) -> {record, "Box", [{"items", element(2, V)}]}.

'__bp_add'(A, B) when is_binary(A), is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.
```

----- RUN LOG -----
```logs
2
7
null
5
8
true
[6, 8]
box
```
