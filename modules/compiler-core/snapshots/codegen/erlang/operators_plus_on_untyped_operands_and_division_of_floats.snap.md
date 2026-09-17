----- SOURCE CODE -- main.bp
```botopink
fn average(xs: Array<f64>) -> f64 {
    var total = 0.0;
    var n = 0.0;
    loop (xs) { x ->
        total = total + x;
        n = n + 1.0;
    };
    return total / n;
}
fn main() {
    val cat = { x, y -> x + y };
    @print(cat("ab", "cd"));
    @print(average([2.0, 4.0, 9.0]));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

average(Xs) ->
    Total = 0.0,
    N = 0.0,
    {Total@3, N@3} = lists:foldl(fun(X, {Total@1, N@1}) ->
        Total@2 = (Total@1 + X),
        N@2 = (N@1 + 1.0),
        {Total@2, N@2}
    end, {Total, N}, Xs),
    (Total@3 / N@3).

main() ->
    Cat = fun(X, Y) ->
        '__bp_add'(X, Y)
    end,
    '__bp_print'([Cat(<<"ab">>, <<"cd">>)]),
    '__bp_print'([average([2.0, 4.0, 9.0])]).

'__bp_add'(A, B) when is_binary(A), is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
abcd
5.0
```
