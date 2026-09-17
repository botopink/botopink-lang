----- SOURCE CODE -- main.bp
```botopink
fn abs(n: i32) -> i32 {
    val result = if (n < 0) -n else n;
    return result;
}
fn main() {
    @print(abs(-5));
    @print(abs(3));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-compile({no_auto_import,[abs/1]}).
-export(['_botopink_main'/0, main/1]).

abs(N) ->
    Result = case (N < 0) of
        true ->
            (-N);
        false ->
            N
    end,
    Result.

main() ->
    '__bp_print'([abs((-5))]),
    '__bp_print'([abs(3)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
5
3
```
