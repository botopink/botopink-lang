----- SOURCE CODE -- main.bp
```botopink
val Counter = record {
    count: i32 = 0,
    fn inc() {
        self.count += 1;
    }
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Counter: count

inc() ->
    %% field assignment is not directly supported in Erlang.
```

----- RUN LOG -----
```logs
```
