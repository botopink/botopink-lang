----- SOURCE CODE -- main.bp
```botopink
val processamento = loop (0..10) { i ->
    if (i % 2 == 0) {
        break i;
    };
};
fn main() {
    @print(processamento);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).


main() ->
    io:format("~p~n", [Processamento]).

'_botopink_main'() ->
    Processamento = lists:foreach(fun(I) ->
        case ((I rem 2) =:= 0) of
            true ->
                I;
            _ -> ok
        end
    end, lists:seq(0, (10) - 1)),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
