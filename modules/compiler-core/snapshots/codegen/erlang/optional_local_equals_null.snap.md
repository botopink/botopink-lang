----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val x: ?i32 = null;
    if (x == null) {
        @print(1);
    } else {
        @print(0);
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    X = undefined,
    case (X =:= undefined) of
        true ->
            io:format("~p~n", [1]);
        false ->
            io:format("~p~n", [0])
    end.

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
1
```
