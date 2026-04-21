----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert false, "error message";
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    true = (False).
```
