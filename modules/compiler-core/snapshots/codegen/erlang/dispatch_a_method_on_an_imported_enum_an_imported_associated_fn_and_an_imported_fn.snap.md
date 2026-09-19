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
-export([make/0, zero/0, bump/1, area/1]).

%% type Counter: n

zero() ->
    #{n => 0}.

bump(Self) ->
    (maps:get(n, Self) + 1).

%% type Shape
%%   Circle(radius)
%%   Square(side)

area(Self) ->
    case Self of
        {'Circle', R} ->
            ((R * R) * 3);
        {'Square', S} ->
            (S * S)
    end.

make() ->
    #{n => 41}.
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
    C = geometry:zero(),
    '__bp_print'([geometry:bump(C)]),
    '__bp_print'([geometry:area({'Square', 4})]),
    '__bp_print'([geometry:bump(geometry:make())]).

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
1
16
42
```
