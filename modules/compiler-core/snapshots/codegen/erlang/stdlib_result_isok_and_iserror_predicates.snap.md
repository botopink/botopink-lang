----- SOURCE CODE -- main.bp
```botopink
fn parseAge(s: string) -> Result<i32, string> { panic("not implemented"); }
fn main() {
    val r = parseAge("42");
    val ok = r.isOk();
    val bad = r.isError();
}

import {failure.panic} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export(['__bp_priv__parseAge'/1, '__bp_priv__main'/0]).

parseAge(S) ->
    erlang:error({panic, <<"not implemented">>}).

main() ->
    R = parseAge(<<"42">>),
    Ok = (fun(__BpR) -> case __BpR of {ok, _} -> true; _ -> false end end)(R),
    Bad = (fun(__BpR) -> case __BpR of {error, _} -> true; _ -> false end end)(R).

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__parseAge'(A0) -> parseAge(A0).

'__bp_priv__main'() -> main().
```

----- RUN LOG -----
```logs
```
