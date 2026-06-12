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
    io:format("~p~n", [Result]),
    Result.

main() ->
    classify(0),
    classify(1),
    classify(7).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"zero">>
<<"one">>
<<"many">>
```
