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

%% type Pipeline: items
```

----- ERLANG -- main__t__list.erl
```erlang
-module(main__t__list).
-export([map/2]).

map(Items, F) ->
    lists:map(F, Items).
```

----- ERLANG -- main__t__pipeline.erl
```erlang
-module(main__t__pipeline).
-export([run/2]).

run(Self, F) ->
    main__t__list:map(maps:get(items, Self), F).
```

----- RUN LOG -----
```logs
```
