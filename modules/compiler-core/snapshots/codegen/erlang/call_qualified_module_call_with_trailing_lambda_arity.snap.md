----- SOURCE CODE -- main.bp
```botopink
record Pipeline {
    items: i32[],
    fn doubled(self: Self) -> i32[] {
        return List.map(self.items) { x ->
            return x * 2;
        };
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Pipeline: items

doubled(Self) ->
    list:map(maps:get(items, Self), fun(X) ->
        (X * 2)
    end).
```

----- RUN LOG -----
```logs
```
