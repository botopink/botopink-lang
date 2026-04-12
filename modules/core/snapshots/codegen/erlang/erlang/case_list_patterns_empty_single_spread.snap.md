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
-module(main).

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
```
