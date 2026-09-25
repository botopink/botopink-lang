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
-module(test@main).

%% type List: tag

%% type Pipeline: items
```

----- ERLANG -- test@main@@List.erl
```erlang
-module(test@main@@List).
-export([each/2, '__bp_get'/2, '__bp_format'/1]).

each(Items, F) ->
    Items.

'__bp_get'(V, tag) -> element(2, V).

'__bp_format'(V) -> {record, "List", [{"tag", element(2, V)}]}.
```

----- ERLANG -- test@main@@Pipeline.erl
```erlang
-module(test@main@@Pipeline).
-export([doubled/1, '__bp_get'/2, '__bp_format'/1]).

doubled(Self) ->
    test@main@@List:each(element(2, Self), fun() ->
        2
    end).

'__bp_get'(V, items) -> element(2, V).

'__bp_format'(V) -> {record, "Pipeline", [{"items", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
