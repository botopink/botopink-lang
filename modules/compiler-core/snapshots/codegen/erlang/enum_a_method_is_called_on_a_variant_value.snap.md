----- SOURCE CODE -- main.bp
```botopink
pub enum Shape {
    Circle(radius: i32),
    Square(side: i32),

    pub fn area(self: Self) -> i32 {
        return case self {
            Circle(r) -> r * r * 3;
            Square(s) -> s * s;
        };
    }
}

pub fn main() {
    @print(Shape.Square(side: 4).area());
    @print(Shape.Circle(radius: 2).area());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).
-export([main/0]).

%% enum Shape
%%   Circle(radius)
%%   Square(side)

area(Self) ->
    case Self of
        {'Circle', R} ->
            ((R * R) * 3);
        {'Square', S} ->
            (S * S)
    end.

main() ->
    '__bp_print'([area({'Square', 4})]),
    '__bp_print'([area({'Circle', 2})]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
16
12
```
