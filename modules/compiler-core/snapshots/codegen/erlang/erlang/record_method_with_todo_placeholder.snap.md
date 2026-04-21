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

-record(Unimplemented, {id}).

process() ->
    erlang:error({todo, "not implemented"}).
```
