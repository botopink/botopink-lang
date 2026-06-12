----- SOURCE CODE -- main.bp
```botopink
val Point = struct {
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

%% struct Point: x, y

sum() ->
    (maps:get(x, Self) + maps:get(y, Self)).
```

----- RUN LOG -----
```logs
```
