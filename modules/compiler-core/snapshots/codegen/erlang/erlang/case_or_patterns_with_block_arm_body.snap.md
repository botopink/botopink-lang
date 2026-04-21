----- SOURCE CODE -- main.bp
```botopink
val parity = case 5 {
    0 | 2 | 4 -> "even";
    _      -> {
        val value = "odd";
        break value;
    };
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

parity() ->
    case 5 of
        0 ->
            <<"even">>;
        2 ->
            <<"even">>;
        4 ->
            <<"even">>;
        _ ->
            Value = <<"odd">>,
            Value
    end.
```
