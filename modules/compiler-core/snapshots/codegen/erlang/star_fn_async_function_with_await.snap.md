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
    (A + A).
```

----- RUN LOG -----
```logs
```
