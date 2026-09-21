----- SOURCE CODE -- main.bp
```botopink
type Unimplemented(id: i32) {
    fn process(self: Self) -> string {
        return @todo();
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Unimplemented: id
```

----- ERLANG -- main__t__unimplemented.erl
```erlang
-module(main__t__unimplemented).
-export([process/1]).

process(Self) ->
    erlang:error({todo, "not implemented"}).
```

----- RUN LOG -----
```logs
```
