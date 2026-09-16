----- SOURCE CODE -- main.bp
```botopink
val ids = [10, 20, 30];
val dobrados = loop (ids) { id ->
    break id * 2;
};
fn main() {
    @print(dobrados);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).



main() ->
    io:format("~p~n", [Dobrados]).

'_botopink_main'() ->
    Ids = [10, 20, 30],
    Dobrados = lists:foreach(fun(Id) ->
        (Id * 2)
    end, Ids),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
COMPILE ERROR (erlc):
main.erl:7:24: variable 'Dobrados' is unbound
```
