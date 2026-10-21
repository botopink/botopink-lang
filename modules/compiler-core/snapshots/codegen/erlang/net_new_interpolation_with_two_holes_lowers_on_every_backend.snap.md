----- SOURCE CODE -- main.bp
```botopink
fn label(a: string, b: string) -> string {
    return "${a}-${b}";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__label'/2]).

label(A, B) ->
    <<A/binary, "-", B/binary>>.

'__bp_priv__label'(A0, A1) -> label(A0, A1).
```

----- RUN LOG -----
```logs
```
