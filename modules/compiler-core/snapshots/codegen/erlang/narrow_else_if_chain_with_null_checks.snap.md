----- SOURCE CODE -- main.bp
```botopink
fn classify(x: ?i32) -> string {
    if (x == 0) { return "zero"; }
    else if (x != 0) { return "nonzero: " + x; }
    else { return "null"; }
}
fn main() {
    @print(classify(42));
    @print(classify(0));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

classify(X) ->
    case (X =:= 0) of
        true ->
            <<"zero">>;
        false ->
            case (X =/= 0) of
                true ->
                    (<<"nonzero: ">> + X);
                false ->
                    <<"null">>
            end
    end.

main() ->
    io:format("~p~n", [classify(42)]),
    io:format("~p~n", [classify(0)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
