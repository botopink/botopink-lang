----- SOURCE CODE -- main.bp
```botopink
fn countdown(n: i32) {
    loop (0..n) { i ->
        @print(n - i);
    };
}
fn main() {
    countdown(3);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

countdown(N) ->
    lists:foreach(fun(I) ->
        '__bp_print'([(N - I)])
    end, lists:seq(0, (N) - 1)).

main() ->
    countdown(3).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
3
2
1
```
