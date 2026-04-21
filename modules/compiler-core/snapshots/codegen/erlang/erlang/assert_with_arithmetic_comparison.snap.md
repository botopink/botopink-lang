----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert 1.0 + 2.0 == 3.0;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    true = (((1.0 + 2.0) =:= 3.0)).
```
