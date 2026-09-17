----- SOURCE CODE -- main.bp
```botopink
val Point = record {
    x: i32,
    y: i32,
    fn sum() -> i32 {
        return self.x + self.y;
    }
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Point: x, y

sum() ->
    '__bp_add'(maps:get(x, Self), maps:get(y, Self)).

'__bp_add'(A, B) when is_binary(A), is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.
```

----- RUN LOG -----
```logs
```
