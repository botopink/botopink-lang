----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val xs = [1, 2, 3];
    val ys = ["a", "b", "c"];
    @print(xs.zip(ys));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Array

array_range(Start, Stop) ->
    case (Start >= Stop) of
        true ->
            [];
        false ->
            Head = Start,
            [Head] ++ (array_range((Start + 1), Stop))
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Head = Value,
            [Head] ++ (array_repeat(Value, (Times - 1)))
    end.

main() ->
    Xs = [1, 2, 3],
    Ys = [<<"a">>, <<"b">>, <<"c">>],
    '__bp_print'([lists:zipwith(fun(__X, __Y) -> {__X, __Y} end, lists:sublist(Xs, length(Ys)), lists:sublist(Ys, length(Xs)))]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
[{1,<<"a">>},{2,<<"b">>},{3,<<"c">>}]
```
