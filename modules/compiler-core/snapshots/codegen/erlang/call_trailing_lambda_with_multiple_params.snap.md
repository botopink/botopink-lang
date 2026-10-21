----- SOURCE CODE -- main.bp
```botopink
fn calc(factor: i32, f: fn(i32, i32) -> i32) -> i32 {
    panic("not implemented");
}
fn main() -> void {
    val r = calc(2) { a, b ->
        return 0;
    };
}

import {failure.panic} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export(['__bp_priv__calc'/2, '__bp_priv__main'/0]).

calc(Factor, F) ->
    erlang:error({panic, <<"not implemented">>}).

main() ->
    R = calc(2, fun(A, B) ->
        0
    end).

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__calc'(A0, A1) -> calc(A0, A1).

'__bp_priv__main'() -> main().
```

----- RUN LOG -----
```logs
```
