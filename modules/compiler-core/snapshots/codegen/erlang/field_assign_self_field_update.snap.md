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
-module(main).

%% type Counter: count
```

----- ERLANG -- main__t__counter.erl
```erlang
-module(main__t__counter).
-export([inc/0]).

inc() ->
    %% field assignment is not directly supported in Erlang.
```

----- RUN LOG -----
```logs
```
