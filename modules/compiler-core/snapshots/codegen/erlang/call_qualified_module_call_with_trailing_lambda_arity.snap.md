----- SOURCE CODE -- main.bp
```botopink
type List(tag: i32) {
    fn each(items: i32[], f: fn() -> i32) -> i32[] {
        return items;
    }
}
type Pipeline(
    items: i32[]) {
    fn doubled(self: Self) -> i32[] {
        return List.each(self.items) { ->
            return 2;
        };
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type List: tag

each(Items, F) ->
    Items.

%% type Pipeline: items

doubled(Self) ->
    each(maps:get(items, Self), fun() ->
        2
    end).
```

----- RUN LOG -----
```logs
```
