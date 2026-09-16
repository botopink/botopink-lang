----- SOURCE CODE -- main.bp
```botopink
val sum = 1 + 2;
fn main() {
    @print(sum);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).


main() ->
    io:format("~p~n", [Sum]).

'_botopink_main'() ->
    Sum = (1 + 2),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
COMPILE ERROR (erlc):
main.erl:6:24: variable 'Sum' is unbound
```
