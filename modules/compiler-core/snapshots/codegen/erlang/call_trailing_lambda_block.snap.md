----- SOURCE CODE -- main.bp
```botopink
fn run(f: fn(i32) -> string) -> void {
    panic("not implemented");
}
fn main() -> void {
    run { x ->
        return "done";
    };
}

import {failure.panic} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export(['__bp_priv__run'/1, '__bp_priv__main'/0]).

run(F) ->
    erlang:error({panic, <<"not implemented">>}).

main() ->
    run(fun(X) ->
        <<"done">>
    end).

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__run'(A0) -> run(A0).

'__bp_priv__main'() -> main().
```

----- RUN LOG -----
```logs
```
