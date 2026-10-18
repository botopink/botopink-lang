----- SOURCE CODE -- main.bp
```botopink
fn fetch(x: i32) -> Task<i32> {
    return x;
}
fn loadTwice(x: i32) -> Task<i32> {
    val a = await fetch(x);
    return a + a;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__fetch'/1, '__bp_priv__loadTwice'/1]).

%% @Task — eager lowering
fetch(X) ->
    X.

%% @Task — eager lowering
loadTwice(X) ->
    A = fetch(X),
    '__bp_add'(A, A).

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

'__bp_priv__fetch'(A0) -> fetch(A0).

'__bp_priv__loadTwice'(A0) -> loadTwice(A0).
```

----- RUN LOG -----
```logs
```
