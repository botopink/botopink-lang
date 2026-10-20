----- SOURCE CODE -- main.bp
```botopink
fn parseAge(s: string) -> Result<i32, string> { panic("not implemented"); }
fn validate(n: i32) -> Result<i32, string> { panic("not implemented"); }
fn main() -> void {
    val r = parseAge("42")
        .map({ n -> n + 1 })
        .flatMap({ n -> validate(n) })
        .unwrapOr(0);
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
    R = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (0) end end)((fun(__BpR) -> case __BpR of {ok, __BpV1} -> (fun(N) ->
        validate(N)
    end)(__BpV1); _ -> __BpR end end)((fun(__BpR) -> case __BpR of {ok, __BpV2} -> {ok, (fun(N) ->
        '__bp_int'((N + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:5:23">>)
    end)(__BpV2)}; _ -> __BpR end end)(parseAge(<<"42">>)))).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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
