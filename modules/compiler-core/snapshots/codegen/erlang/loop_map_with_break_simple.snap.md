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

ids() ->
    [10, 20, 30].

dobrados() ->
    lists:map(fun(Id) ->
        (Id * 2)
    end, ids()).

main() ->
    io:format("~p~n", [dobrados()]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
[20,40,60]
```
