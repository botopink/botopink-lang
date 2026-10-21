----- SOURCE CODE -- main.bp
```botopink
fn describe() -> string {
    val items = ["a", "b", "c"];
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__describe'/0]).

describe() ->
    Items = [<<"a">>, <<"b">>, <<"c">>],
    case Items of
        [] ->
            <<"empty">>;
        [X] ->
            <<"one">>;
        [First | Rest] ->
            <<"many">>
    end.

'__bp_priv__describe'() -> describe().
```

----- RUN LOG -----
```logs
```
