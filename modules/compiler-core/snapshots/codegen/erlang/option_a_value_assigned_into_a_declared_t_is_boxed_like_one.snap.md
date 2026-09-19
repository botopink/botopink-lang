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
-module(main).
-export(['_botopink_main'/0, main/1]).

%% type Box: items

total(Self) ->
    Sum = lists:foldl(fun(N, Sum) ->
        '__bp_add'(Sum, N)
    end, 0, maps:get(items, Self)),
    Sum.

isBig(Self) ->
    (length(maps:get(items, Self)) > 1).

doubled(Self) ->
    lists:map(fun(N) ->
        (N * 2)
    end, maps:get(items, Self)).

label(Self) ->
    <<"box">>.

main() ->
    Seen = lists:foldl(fun(N, Seen) ->
        N
    end, 0, [1, 2]),
    '__bp_print'([Seen]),
    B = #{items => [3, 4]},
    '__bp_print'([total(B)]),
    H = undefined,
    '__bp_print'([H]),
    H@1 = 5,
    '__bp_print'([H@1]),
    Acc = lists:foldl(fun(N, Acc) ->
        N
    end, undefined, [7, 8]),
    '__bp_print'([Acc]),
    '__bp_print'([isBig(B)]),
    '__bp_print'([doubled(B)]),
    '__bp_print'([label(B)]).

'__bp_add'(A, B) when is_binary(A), is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
2
7
undefined
5
8
true
[6,8]
box
```
