----- SOURCE CODE -- main.bp
```botopink
val Counter = type(
    count: i32 = 0) {
    fn inc() {
        self.count += 1;
    }
};
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Counter: count
```

----- ERLANG -- test@main@@Counter.erl
```erlang
-module(test@main@@Counter).
-export([inc/0, '__bp_get'/2, '__bp_format'/1]).

inc() ->
    %% field assignment is not directly supported in Erlang.

'__bp_get'(V, count) -> element(2, V).

'__bp_format'(V) -> {record, "Counter", [{"count", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
