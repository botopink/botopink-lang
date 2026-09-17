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
    '__bp_print'([dobrados()]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
[20,40,60]
```
