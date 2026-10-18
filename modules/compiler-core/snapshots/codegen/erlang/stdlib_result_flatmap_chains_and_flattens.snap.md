----- SOURCE CODE -- main.bp
```botopink
fn parseAge(s: string) -> Result<i32, string> { panic("not implemented"); }
fn validate(n: i32) -> Result<i32, string> { panic("not implemented"); }
fn main() {
    val r = parseAge("42").flatMap({ n -> validate(n) });
}

import {failure.panic} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export(['__bp_priv__parseAge'/1, '__bp_priv__validate'/1, '__bp_priv__main'/0]).

parseAge(S) ->
    erlang:error({panic, <<"not implemented">>}).

validate(N) ->
    erlang:error({panic, <<"not implemented">>}).

main() ->
    R = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> (fun(N) ->
        validate(N)
    end)(__BpV0); _ -> __BpR end end)(parseAge(<<"42">>)).

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__parseAge'(A0) -> parseAge(A0).

'__bp_priv__validate'(A0) -> validate(A0).

'__bp_priv__main'() -> main().
```

----- RUN LOG -----
```logs
```
