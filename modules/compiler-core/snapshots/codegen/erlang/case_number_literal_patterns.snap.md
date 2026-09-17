----- SOURCE CODE -- main.bp
```botopink
fn classify(n: i32) -> string {
    val result = case n {
        0 -> "zero";
        1 -> "one";
        _ -> "many";
    };
    @print(result);
    return result;
}
fn main() {
    classify(0);
    classify(1);
    classify(7);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

classify(N) ->
    Result = case N of
        0 ->
            <<"zero">>;
        1 ->
            <<"one">>;
        _ ->
            <<"many">>
    end,
    '__bp_print'([Result]),
    Result.

main() ->
    classify(0),
    classify(1),
    classify(7).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
zero
one
many
```
