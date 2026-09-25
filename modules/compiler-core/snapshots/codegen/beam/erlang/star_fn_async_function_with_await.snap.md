----- SOURCE CODE -- main.bp
```botopink
fn fetch(x: i32) -> @Task<i32> {
    return x;
}
fn loadTwice(x: i32) -> @Task<i32> {
    val a = await fetch(x);
    return a + a;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% @Task — eager lowering
fetch(X) ->
    X.

%% @Task — eager lowering
loadTwice(X) ->
    A = fetch(X),
    '__bp_add'(A, A).

'__bp_add'(A, B) when is_binary(A), is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.
```

----- RUN LOG -----
```logs
```
