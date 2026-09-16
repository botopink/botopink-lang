----- SOURCE CODE -- main.bp
```botopink
fn greet(x: ?string) -> string {
    if (x == null) { return "nobody"; };
    return "hello " + x;
}
fn main() {
    @print(greet("world"));
    @print(greet(null));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

greet(X) ->
    case (X =:= undefined) of
        true ->
            <<"nobody">>;
        _ ->
            <<"hello ", X/binary>>
    end.

main() ->
    io:format("~p~n", [greet(<<"world">>)]),
    io:format("~p~n", [greet(undefined)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"hello world">>
<<"nobody">>
```
