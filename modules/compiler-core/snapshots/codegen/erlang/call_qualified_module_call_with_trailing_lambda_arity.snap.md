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

%% type Pipeline: items
```

----- ERLANG -- main__t__list.erl
```erlang
-module(main__t__list).
-export([each/2]).

each(Items, F) ->
    Items.
```

----- ERLANG -- main__t__pipeline.erl
```erlang
-module(main__t__pipeline).
-export([doubled/1]).

doubled(Self) ->
    main__t__list:each(maps:get(items, Self), fun() ->
        2
    end).
```

----- RUN LOG -----
```logs
```
