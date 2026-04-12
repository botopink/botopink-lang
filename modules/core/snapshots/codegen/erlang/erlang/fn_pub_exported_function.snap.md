----- SOURCE CODE -- main.bp
```botopink
pub fn add(a: i32, b: i32) -> i32 {
    return a + b;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([add/2]).

add(A, B) ->
    (A + B).
```
