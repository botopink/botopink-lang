----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [first, second, ..rest] = items catch [];
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case Items of [First, Second | Rest] -> Items; _ -> [] end.
```
