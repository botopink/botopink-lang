----- SOURCE CODE -- main.bp
```botopink
fn fail() {
    panic("something went wrong");
}

import {failure.panic} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__fail'/0]).

fail() ->
    erlang:error({panic, <<"something went wrong">>}).

'__bp_priv__fail'() -> fail().
```

----- RUN LOG -----
```logs
```
