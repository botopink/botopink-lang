----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0    -> "zero";
    _ -> 1;
};
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_init'/0]).

result() ->
    case persistent_term:get({test@main, result}, '__bp_unset') of
        '__bp_unset' -> __BpV = case 42 of
            0 ->
                <<"zero">>;
            _ ->
                1
        end, persistent_term:put({test@main, result}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'_botopink_init'() ->
    result(),
    ok.
```

----- RUN LOG -----
```logs
```
