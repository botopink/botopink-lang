----- SOURCE CODE -- main.bp
```botopink
val v1 = comptime 1 + 1;
fn main() {
    @print(v1);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val v1 = comptime 1 + 1 → 2
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).


main() ->
    io:format("~p~n", [V1]).

'_botopink_main'() ->
    V1 = 2,
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
