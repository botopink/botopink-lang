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
-module(main).

getName(Name) ->
    case Name of
        undefined -> undefined;
        _ ->
            N
    end,
    <<"unknown">>.
```
