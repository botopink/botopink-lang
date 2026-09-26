----- SOURCE CODE -- main.bp
```botopink
val Point = type(
    x: i32,
    y: i32) {
    fn sum(self: Self) -> i32 {
        return self.x + self.y;
    }
};
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Point: x, y
```

----- ERLANG -- test@main@@Point.erl
```erlang
-module(test@main@@Point).
-export([sum/1, '__bp_get'/2, '__bp_format'/1]).

sum(Self) ->
    '__bp_add'(element(2, Self), element(3, Self)).

'__bp_get'(V, x) -> element(2, V);
'__bp_get'(V, y) -> element(3, V).

'__bp_format'(V) -> {record, "Point", [{"x", element(2, V)}, {"y", element(3, V)}]}.

'__bp_add'(A, B) when is_binary(A), is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.
```

----- RUN LOG -----
```logs
```
