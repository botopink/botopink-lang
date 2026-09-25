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
-module(test@main).
-export(['_botopink_init'/0]).

parity() ->
    case persistent_term:get({test@main, parity}, '__bp_unset') of
        '__bp_unset' -> __BpV = case 5 of
            0 ->
                <<"even">>;
            2 ->
                <<"even">>;
            4 ->
                <<"even">>;
            _ ->
                Value = <<"odd">>,
                Value
        end, persistent_term:put({test@main, parity}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'_botopink_init'() ->
    parity(),
    ok.
```

----- RUN LOG -----
```logs
```
