----- SOURCE CODE -- main.bp
```botopink
fn classify(n: i32) -> string {
    return case n {
        x if x > 0 -> "positive";
        0 -> "zero";
        _ -> "negative";
    };
}
fn main() {
    @print(classify(5));
    @print(classify(0));
    @print(classify(-3));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

classify(N) ->
    case N of
        X when (X > 0) ->
            <<"positive">>;
        0 ->
            <<"zero">>;
        _ ->
            <<"negative">>
    end.

main() ->
    '__bp_print'([classify(5)]),
    '__bp_print'([classify(0)]),
    '__bp_print'([classify((-3))]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
positive
zero
negative
```
