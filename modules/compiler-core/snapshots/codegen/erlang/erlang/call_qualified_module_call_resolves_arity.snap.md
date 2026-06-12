----- SOURCE CODE -- main.bp
```botopink
record Pipeline {
    items: i32[],
    fn run(self: Self, f: fn(item: i32) -> i32) -> i32[] {
        return List.map(self.items, f);
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Pipeline: items

run(Self, F) ->
    list:map(maps:get(items, Self), F).
```

----- RUN LOG -----
```logs
```
