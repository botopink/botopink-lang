----- SOURCE CODE -- main.bp
```botopink
fn isString(x: ?string) -> x is string {
    if (x) { s -> return true; };
    return false;
}
fn main() {
    @print(isString("hello"));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

isString(X) ->
    case X of
        undefined -> undefined;
        S ->
            true;
        _ -> ok
    end,
    false.

main() ->
    io:format("~p~n", [isString(<<"hello">>)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
false
```
