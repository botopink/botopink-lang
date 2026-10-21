----- SOURCE CODE -- main.bp
```botopink
fn getName(name: ?string) -> string {
    if (name) { n ->
        return n;
    };
    return "unknown";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__getName'/1]).

getName(Name) ->
    case Name of
        undefined ->
            <<"unknown">>;
        N ->
            N
    end.

'__bp_priv__getName'(A0) -> getName(A0).
```

----- RUN LOG -----
```logs
```
