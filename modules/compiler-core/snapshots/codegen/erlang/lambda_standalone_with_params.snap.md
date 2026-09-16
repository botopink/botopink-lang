----- SOURCE CODE -- main.bp
```botopink
val add = { x, y ->
    x + y;
};
val result = add(10, 20);
fn main() {
    @print(result);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

add() ->
    fun(X, Y) ->
        (X + Y)
    end.

result() ->
    (add())(10, 20).

main() ->
    io:format("~p~n", [result()]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
30
```
