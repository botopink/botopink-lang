----- SOURCE CODE -- main.bp
```botopink
fn label(a: string, b: string) -> string {
    return "${a}-${b}";
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

label(A, B) ->
    (((<<"">> + A) + <<"-">>) + B).
```

----- RUN LOG -----
```logs
```
