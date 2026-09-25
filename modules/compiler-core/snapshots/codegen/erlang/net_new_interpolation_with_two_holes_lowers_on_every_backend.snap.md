----- SOURCE CODE -- main.bp
```botopink
fn label(a: string, b: string) -> string {
    return "${a}-${b}";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

label(A, B) ->
    <<A/binary, "-", B/binary>>.
```

----- RUN LOG -----
```logs
```
