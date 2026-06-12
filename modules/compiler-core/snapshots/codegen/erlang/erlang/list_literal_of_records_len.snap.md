----- SOURCE CODE -- main.bp
```botopink
record P { x: i32, y: i32 }
fn main() {
    val pts = [P(x: 1, y: 2), P(x: 3, y: 4)];
    @print(pts.len);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record P: x, y

main() ->
    Pts = [#{x => 1, y => 2}, #{x => 3, y => 4}],
    io:format("~p~n", [length(Pts)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
2
```
