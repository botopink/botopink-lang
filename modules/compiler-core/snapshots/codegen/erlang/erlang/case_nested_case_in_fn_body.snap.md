----- SOURCE CODE -- main.bp
```botopink
fn process(x: i32) -> string {
    return case (x) {
        0 -> {
            break case (x) {
                0 -> "zero";
                _ -> "other";
            };
        };
        _ -> "non-zero";
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

process(X) ->
    case X of
        0 ->
            case X of
                0 ->
                    <<"zero">>;
                _ ->
                    <<"other">>
            end;
        _ ->
            <<"non-zero">>
    end.
```
