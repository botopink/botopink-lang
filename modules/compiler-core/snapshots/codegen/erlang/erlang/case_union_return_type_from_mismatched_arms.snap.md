----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0    -> "zero";
    _ -> 1;
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

result() ->
    case 42 of
        0 ->
            <<"zero">>;
        _ ->
            1
    end.
```
