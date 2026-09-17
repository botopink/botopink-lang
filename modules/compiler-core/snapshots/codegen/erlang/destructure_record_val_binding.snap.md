----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn describe(p: Point) -> i32 {
    val { x, y } = p;
    @print(x, y);
    return x;
}
fn main() {
    describe(Point(x: 3, y: 4));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record Point: x, y

describe(P) ->
    #{x := X, y := Y} = P,
    '__bp_print'([X, Y]),
    X.

main() ->
    describe(#{x => 3, y => 4}).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
3 4
```
