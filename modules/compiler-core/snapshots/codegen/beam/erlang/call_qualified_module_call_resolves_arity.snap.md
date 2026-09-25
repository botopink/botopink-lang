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
-module(test@main).

%% type List: tag

%% type Pipeline: items
```

----- ERLANG -- test@main@@List.erl
```erlang
-module(test@main@@List).
-export([map/2, '__bp_get'/2, '__bp_format'/1]).

map(Items, F) ->
    lists:map(F, Items).

'__bp_get'(V, tag) -> element(2, V).

'__bp_format'(V) -> {record, "List", [{"tag", element(2, V)}]}.
```

----- ERLANG -- test@main@@Pipeline.erl
```erlang
-module(test@main@@Pipeline).
-export([run/2, '__bp_get'/2, '__bp_format'/1]).

run(Self, F) ->
    test@main@@List:map(element(2, Self), F).

'__bp_get'(V, items) -> element(2, V).

'__bp_format'(V) -> {record, "Pipeline", [{"items", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
