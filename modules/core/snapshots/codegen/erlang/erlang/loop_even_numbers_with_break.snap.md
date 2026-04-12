----- SOURCE CODE -- main.bp
```botopink
val processamento = loop (0..10) { i ->
    if (i % 2 == 0) {
        break i;
    };
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

processamento() ->
    lists:foreach(fun(I) ->
        case ((I rem 2) =:= 0) of
            true ->
                I
        end
    end, lists:seq(0, 10)).
```
