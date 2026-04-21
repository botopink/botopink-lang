----- SOURCE CODE -- main.bp
```botopink
fn extract() {
    val #(a, b) = #(12, "hello");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

extract() ->
    {A, B} = {12, <<"hello">>}.
```
