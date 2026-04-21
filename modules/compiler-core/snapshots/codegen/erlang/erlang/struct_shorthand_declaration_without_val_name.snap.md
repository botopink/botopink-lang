----- SOURCE CODE -- main.bp
```botopink
struct Counter {
    _count: i32 = 0,
    fn increment(self: Self) {
        self._count += 1;
    }
    get count(self: Self) -> i32 {
        return self._count;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Counter, {_count}).

increment() ->
    %% field += not directly supported in Erlang.
```
