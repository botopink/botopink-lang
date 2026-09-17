----- SOURCE CODE -- main.bp
```botopink
fn describe(n: i32) -> string {
    return if (n > 0) "positive" else "non-positive";
}
fn main() {
    @print(describe(5));
    @print(describe(-3));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

describe(N) ->
    case (N > 0) of
        true ->
            <<"positive">>;
        false ->
            <<"non-positive">>
    end.

main() ->
    '__bp_print'([describe(5)]),
    '__bp_print'([describe((-3))]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
positive
non-positive
```
