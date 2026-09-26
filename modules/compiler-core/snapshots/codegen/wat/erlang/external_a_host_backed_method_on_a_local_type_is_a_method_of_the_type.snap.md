----- SOURCE CODE -- main.bp
```botopink
pub type Meter(base: i32) {
    #[@External.Node("""($0.base + $1)"""),
      @External.Erlang("""(element(2, $0) + $1)""")]
    pub declare fn plus(self: Self, n: i32) -> i32;

    #[@External.Node("""[$0.base, $1, $2].join("-")"""),
      @External.Erlang("""iolist_to_binary(lists:join(<<"-">>, [integer_to_binary(element(2, $0)), integer_to_binary($1), $2]))""")]
    pub declare fn label(self: Self, n: i32, tail: string) -> string;

    pub fn twice(self: Self) -> i32 {
        return self.plus(self.base);
    }
}

pub type Level {
    Low,
    High,

    #[@External.Node("""($0.tag === "High" ? $1 * 10 : $1)"""),
      @External.Erlang("""case $0 of 'test@main@@Level__v__high' -> $1 * 10; _ -> $1 end""")]
    pub declare fn scale(self: Self, n: i32) -> i32;
}

pub fn main() {
    val m = Meter(base: 3);
    @print(m.plus(4));
    @print(m.twice());
    @print(m.label(5, "x"));
    @print(Level.High.scale(2));
    @print(Level.Low.scale(2));
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0]).

%% type Meter: base

%% type Level
%%   Low
%%   High

main() ->
    M = {test@main@@Meter, 3},
    '__bp_print'([test@main@@Meter:plus(M, 4)]),
    '__bp_print'([test@main@@Meter:twice(M)]),
    '__bp_print'([test@main@@Meter:label(M, 5, <<"x">>)]),
    '__bp_print'([test@main@@Level:scale(test@main@@Level__v__high, 2)]),
    '__bp_print'([test@main@@Level:scale(test@main@@Level__v__low, 2)]).

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

----- ERLANG -- test@main@@Meter.erl
```erlang
-module(test@main@@Meter).
-export([plus/2, label/3, twice/1, '__bp_get'/2, '__bp_format'/1]).

plus(Self, N) ->
    (element(2, Self) + N).

label(Self, N, Tail) ->
    iolist_to_binary(lists:join(<<"-">>, [integer_to_binary(element(2, Self)), integer_to_binary(N), Tail])).

twice(Self) ->
    plus(Self, element(2, Self)).

'__bp_get'(V, base) -> element(2, V).

'__bp_format'(V) -> {record, "Meter", [{"base", element(2, V)}]}.
```

----- ERLANG -- test@main@@Level.erl
```erlang
-module(test@main@@Level).
-export([scale/2, '__bp_format'/1]).

scale(Self, N) ->
    case Self of 'test@main@@Level__v__high' -> N * 10; _ -> N end.

'__bp_format'(test@main@@Level__v__low) -> {variant, "Level.Low", []};
'__bp_format'(test@main@@Level__v__high) -> {variant, "Level.High", []}.
```

----- RUN LOG -----
```logs
7
6
3-5-x
20
2
```
