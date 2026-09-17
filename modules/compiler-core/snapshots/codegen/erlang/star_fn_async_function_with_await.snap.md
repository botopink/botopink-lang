----- SOURCE CODE -- main.bp
```botopink
#[@future]
fn fetch(x: i32) -> @Future<i32> {
    return x;
}
#[@future]
fn loadTwice(x: i32) -> @Future<i32> {
    val a = await fetch(x);
    return a + a;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% #[@future] / #[@asyncGenerator] — eager lowering
fetch(X) ->
    X.

%% #[@future] / #[@asyncGenerator] — eager lowering
loadTwice(X) ->
    A = fetch(X),
    '__bp_add'(A, A).

'__bp_add'(A, B) when is_binary(A), is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.
```

----- RUN LOG -----
```logs
```
