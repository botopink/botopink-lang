----- SOURCE CODE -- main.bp
```botopink
fn notImplemented() -> void {
    panic("implement this function");
}

import {failure.panic} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__notImplemented'/0]).

notImplemented() ->
    erlang:error({panic, <<"implement this function">>}).

'__bp_priv__notImplemented'() -> notImplemented().
```

----- RUN LOG -----
```logs
```
