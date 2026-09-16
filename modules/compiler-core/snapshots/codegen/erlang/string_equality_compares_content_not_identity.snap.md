----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val left = "fo" + "o";
    val same = left == "foo";
    val diff = "foo" == "bar";
    if (same) {
        @print(1);
    } else {
        @print(0);
    };
    if (diff) {
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
    Left = <<"fo", "o">>,
    Same = (Left =:= <<"foo">>),
    Diff = (<<"foo">> =:= <<"bar">>),
    case Same of
        true ->
            io:format("~p~n", [1]);
        false ->
            io:format("~p~n", [0])
    end,
    case Diff of
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
0
```
