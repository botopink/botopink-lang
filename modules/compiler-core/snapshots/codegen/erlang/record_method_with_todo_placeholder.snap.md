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
-export([process/1, '__bp_get'/2, '__bp_format'/1]).

process(Self) ->
    erlang:error({todo, "not implemented"}).

'__bp_get'(V, id) -> element(2, V).

'__bp_format'(V) -> {record, "Unimplemented", [{"id", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
