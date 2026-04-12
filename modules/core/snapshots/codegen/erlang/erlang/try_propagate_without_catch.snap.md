----- SOURCE CODE -- main.bp
```botopink
fn fetch() -> i32 {
    todo;
}
fn process() -> i32 {
    val r = try fetch();
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

fetch() ->
    erlang:error(not_implemented).

process() ->
    R = fetch(),
    R.
```
