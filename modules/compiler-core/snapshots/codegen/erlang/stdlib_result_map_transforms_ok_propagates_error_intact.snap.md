----- SOURCE CODE -- main.bp
```botopink
fn parseAge(s: string) -> Result<i32, string> { panic("not implemented"); }
fn main() {
    val r = parseAge("42").map({ n -> n + 1 });
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
    R = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> {ok, (fun(N) ->
        '__bp_int'((N + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:3:41">>)
    end)(__BpV0)}; _ -> __BpR end end)(parseAge(<<"42">>)).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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
