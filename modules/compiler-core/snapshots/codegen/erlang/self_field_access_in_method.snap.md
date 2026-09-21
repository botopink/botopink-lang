----- SOURCE CODE -- main.bp
```botopink
val Point = type(
    x: i32,
    y: i32) {
    fn sum() -> i32 {
        return self.x + self.y;
    }
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Point: x, y
```

----- ERLANG -- main__t__point.erl
```erlang
-module(main__t__point).
-export([sum/0]).

sum() ->
    '__bp_add'(maps:get(x, Self), maps:get(y, Self)).

'__bp_add'(A, B) when is_binary(A), is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.
```

----- RUN LOG -----
```logs
```
