----- SOURCE CODE -- main.bp
```botopink
val result = comptime 10 + 20;
fn main() {
    @print(result);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val result = comptime 10 + 20 → 30
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

result() ->
    30.

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
