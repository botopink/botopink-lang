----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val items = [1, 2, 3, 4];
    val assert [first, second, ..rest] = items catch [];
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    Items = [1, 2, 3, 4],
    case Items of [First, Second | Rest] -> Items; _ -> [] end.
```

----- RUN LOG -----
```logs
```
