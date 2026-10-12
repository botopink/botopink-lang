----- SOURCE CODE -- main.bp
```botopink
/// This function greets the user
fn greet(name: string) -> string {
    return name;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__greet'/1]).

%% This function greets the user

greet(Name) ->
    Name.

'__bp_priv__greet'(A0) -> greet(A0).
```

----- RUN LOG -----
```logs
```
