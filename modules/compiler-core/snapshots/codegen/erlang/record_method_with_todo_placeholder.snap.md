----- SOURCE CODE -- main.bp
```botopink
record Unimplemented { id: i32,
    fn process(self: Self) -> string {
        return @todo();
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Unimplemented: id

process(Self) ->
    erlang:error({todo, "not implemented"}).
```

----- RUN LOG -----
```logs
```
