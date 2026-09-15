----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "yes";
    if (s == "yes") {
        @print(42);
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
    S = <<"yes">>,
    case (S =:= <<"yes">>) of
        true ->
            io:format("~p~n", [42]);
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
42
```
