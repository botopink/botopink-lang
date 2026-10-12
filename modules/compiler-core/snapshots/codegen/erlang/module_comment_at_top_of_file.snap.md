----- SOURCE CODE -- main.bp
```botopink
//// This module provides utility functions
//// for string manipulation

fn capitalize(s: string) -> string {
    return s;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__capitalize'/1]).

%%% This module provides utility functions

%%% for string manipulation

capitalize(S) ->
    S.

'__bp_priv__capitalize'(A0) -> capitalize(A0).
```

----- RUN LOG -----
```logs
```
