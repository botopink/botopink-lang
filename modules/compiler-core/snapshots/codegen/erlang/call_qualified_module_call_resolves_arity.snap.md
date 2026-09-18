----- SOURCE CODE -- main.bp
```botopink
type List(tag: i32) {
    fn map(items: i32[], f: fn(item: i32) -> i32) -> i32[] {
        return items.map(f);
    }
}
type Pipeline(
    items: i32[]) {
    fn run(self: Self, f: fn(item: i32) -> i32) -> i32[] {
        return List.map(self.items, f);
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type List: tag

map(Items, F) ->
    lists:map(F, Items).

%% type Pipeline: items

run(Self, F) ->
    map(maps:get(items, Self), F).
```

----- RUN LOG -----
```logs
```
