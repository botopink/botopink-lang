----- SOURCE CODE -- main.bp
```botopink
fn double(x: i32) -> i32 {
    val result = x * 2;
    return result;
}
val output = double(10);
fn main() {
    @print(output);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

double(X) ->
    Result = (X * 2),
    Result.


main() ->
    io:format("~p~n", [Output]).

'_botopink_main'() ->
    Output = double(10),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
COMPILE ERROR (erlc):
main.erl:10:24: variable 'Output' is unbound
```
