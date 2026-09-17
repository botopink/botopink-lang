----- SOURCE CODE -- main.bp
```botopink
fn pick(xs: Array<string>) -> string {
    var first = "";
    var last = "";
    loop (xs) { x, i ->
        if (i == 0) { first = x; };
        last = x;
    };
    return first + "-" + last;
}
fn weigh(xs: Array<i32>) -> i32 {
    var total = 0;
    loop (xs, 1..) { x, i ->
        total = total + x * i;
    };
    return total;
}
fn main() {
    @print(pick(["a", "b", "c"]));
    @print(weigh([10, 20, 30]));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

pick(Xs) ->
    First = <<"">>,
    Last = <<"">>,
    {First@4, Last@3} = lists:foldl(fun({I, X}, {First@1, Last@1}) ->
        First@3 = case (I =:= 0) of
            true ->
                First@2 = X,
                First@2;
            _ ->
                First@1
        end,
        Last@2 = X,
        {First@3, Last@2}
    end, {First, Last}, lists:enumerate(0, Xs)),
    <<First@4/binary, "-", Last@3/binary>>.

weigh(Xs) ->
    Total = 0,
    Total@3 = lists:foldl(fun({I, X}, Total@1) ->
        Total@2 = (Total@1 + (X * I)),
        Total@2
    end, Total, lists:enumerate(1, Xs)),
    Total@3.

main() ->
    '__bp_print'([pick([<<"a">>, <<"b">>, <<"c">>])]),
    '__bp_print'([weigh([10, 20, 30])]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
a-c
140
```
