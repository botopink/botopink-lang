----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val labels = ["a", "bb", "ccc"];
    @print(labels.len);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Labels = [<<"a">>, <<"bb">>, <<"ccc">>],
    io:format("~p~n", [length(Labels)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
3
```
