----- SOURCE CODE -- main.bp
```botopink
val Counter = struct {
    count: i32 = 0,
    fn inc() {
        self.count += 1;
    }
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% struct Counter: count

inc() ->
    %% field assignment is not directly supported in Erlang.
```

----- RUN LOG -----
```logs
```
