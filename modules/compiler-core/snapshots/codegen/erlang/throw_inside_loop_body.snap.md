----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn validate(items: i32) -> @Result<i32, string> {
    loop (0..items) { i ->
        if (i > 2) { throw "too many"; };
    };
    return items;
}
fn main() {
    @print(validate(2).isOk());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

validate(Items) ->
    lists:foreach(fun(I) ->
        case (I > 2) of
            true ->
                {error, <<"too many">>};
            _ -> ok
        end
    end, lists:seq(0, (Items) - 1)),
    {ok, Items}.

main() ->
    '__bp_print'([(fun(R) -> case R of {ok, _} -> true; _ -> false end end)(validate(2))]).

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
true
```
