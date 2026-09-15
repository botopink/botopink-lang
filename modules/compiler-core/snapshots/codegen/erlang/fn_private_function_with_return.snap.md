----- SOURCE CODE -- main.bp
```botopink
fn double(x: i32) -> i32 {
    return x * 2;
}
val result = double(5);
fn main() {
    @print(result);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

double(X) ->
    (X * 2).


main() ->
    io:format("~p~n", [Result]).

'_botopink_main'() ->
    Result = double(5),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
