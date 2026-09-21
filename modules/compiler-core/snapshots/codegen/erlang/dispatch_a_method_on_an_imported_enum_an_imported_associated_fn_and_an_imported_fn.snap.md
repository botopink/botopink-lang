----- SOURCE CODE -- geometry.bp
```botopink
pub type Counter(n: i32) {
    pub fn zero() -> Self { return Counter(n: 0); }
    pub fn bump(self: Self) -> i32 { return self.n + 1; }
}

pub type Shape {
    Circle(radius: i32),
    Square(side: i32),

    pub fn area(self: Self) -> i32 {
        return case self {
            Circle(r) -> r * r * 3;
            Square(s) -> s * s;
        };
    }
}

pub fn make() -> Counter { return Counter(n: 41); }
```

----- ERLANG -- geometry.erl
```erlang
-module(geometry).
-export([make/0]).

%% type Counter: n

%% type Shape
%%   Circle(radius)
%%   Square(side)

make() ->
    {geometry__t__counter, 41}.
```

----- ERLANG -- geometry__t__counter.erl
```erlang
-module(geometry__t__counter).
-export([zero/0, bump/1, '__bp_get'/2, '__bp_format'/1]).

zero() ->
    {geometry__t__counter, 0}.

bump(Self) ->
    (element(2, Self) + 1).

'__bp_get'(V, n) -> element(2, V).

'__bp_format'(V) -> {record, "Counter", [{"n", element(2, V)}]}.
```

----- ERLANG -- geometry__t__shape.erl
```erlang
-module(geometry__t__shape).
-export([area/1, '__bp_format'/1]).

area(Self) ->
    case Self of
        {geometry__t__shape__v__circle, R} ->
            ((R * R) * 3);
        {geometry__t__shape__v__square, S} ->
            (S * S)
    end.

'__bp_format'({geometry__t__shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"radius", F0}]};
'__bp_format'({geometry__t__shape__v__square, F0}) -> {variant, "Shape.Square", [{"side", F0}]}.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {Counter, Shape, make} from "geometry";
fn main() {
    val c: Counter = Counter.zero();
    @print(c.bump());
    @print(Shape.Square(side: 4).area());
    @print(make().bump());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import Counter, Shape, make

main() ->
    C = geometry__t__counter:zero(),
    '__bp_print'([geometry__t__counter:bump(C)]),
    '__bp_print'([geometry__t__shape:area({geometry__t__shape__v__square, 4})]),
    '__bp_print'([geometry__t__counter:bump(geometry:make())]).

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
1
16
42
```
