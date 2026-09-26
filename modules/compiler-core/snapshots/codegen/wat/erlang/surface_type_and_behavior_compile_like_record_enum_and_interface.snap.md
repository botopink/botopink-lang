----- SOURCE CODE -- main.bp
```botopink
behavior Shape {
    fn area(self: Self) -> i32;
}

type Square(side: i32) implement Shape {
    fn area(self: Self) -> i32 {
        return self.side * self.side;
    }
}

type Size { Small, Large(n: i32) }

fn weight(s: Size) -> i32 {
    return case s {
        Small -> 1;
        Large(n) -> n;
    };
}

fn main() {
    val sq = Square(side: 3);
    @print(sq.area());
    @print(weight(Size.Large(n: 5)) + weight(Size.Small));
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% behavior Shape

%% type Square: side

%% type Size
%%   Small
%%   Large(n)

weight(S) ->
    case S of
        test@main@@Size__v__small ->
            1;
        {test@main@@Size__v__large, N} ->
            N
    end.

main() ->
    Sq = {test@main@@Square, 3},
    '__bp_print'([test@main@@Square:area(Sq)]),
    '__bp_print'([(weight({test@main@@Size__v__large, 5}) + weight(test@main@@Size__v__small))]).

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

----- ERLANG -- test@main@@Square.erl
```erlang
-module(test@main@@Square).
-export([area/1, '__bp_get'/2, '__bp_format'/1]).

area(Self) ->
    (element(2, Self) * element(2, Self)).

'__bp_get'(V, side) -> element(2, V).

'__bp_format'(V) -> {record, "Square", [{"side", element(2, V)}]}.
```

----- ERLANG -- test@main@@Size.erl
```erlang
-module(test@main@@Size).
-export(['__bp_format'/1]).

'__bp_format'(test@main@@Size__v__small) -> {variant, "Size.Small", []};
'__bp_format'({test@main@@Size__v__large, F0}) -> {variant, "Size.Large", [{"n", F0}]}.
```

----- RUN LOG -----
```logs
9
6
```
