----- SOURCE CODE -- main.bp
```botopink
fn main() -> bool {
    return isEven(10);
}

fn isEven(n: i32) -> bool {
    if (n == 0) { return true; };
    return isOdd(n - 1);
}

fn isOdd(n: i32) -> bool {
    if (n == 0) { return false; };
    return isEven(n - 1);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

main() ->
    isEven(10).

isEven(N) ->
    case (N =:= 0) of
        true ->
            true;
        _ ->
            isOdd('__bp_int'((N - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at main.bp:7:20">>))
    end.

isOdd(N) ->
    case (N =:= 0) of
        true ->
            false;
        _ ->
            isEven('__bp_int'((N - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at main.bp:12:21">>))
    end.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
