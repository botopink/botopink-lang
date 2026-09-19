----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val fs = [1.5, 2.5];
    @print(fs[0]);
    @print(fs.at(0));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Fs = [1.5, 2.5],
    '__bp_print'(['__bp_index'(Fs, 0)]),
    '__bp_print'([(fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(Fs, 0)]).

'__bp_index'(Recv, I) when is_list(Recv), is_integer(I), I >= 0, I < length(Recv) -> lists:nth(I + 1, Recv);
'__bp_index'(Recv, I) when is_binary(Recv), is_integer(I), I >= 0 -> string:slice(Recv, I, 1);
'__bp_index'(Recv, I) when is_tuple(Recv), is_integer(I), I >= 0, I < tuple_size(Recv) -> element(I + 1, Recv);
'__bp_index'(Recv, I) when is_list(Recv), is_integer(I) -> undefined;
'__bp_index'(Recv, I) when is_tuple(Recv), is_integer(I) -> undefined;
'__bp_index'(Recv, I) -> erlang:error({bp_unsupported_index, Recv, I}).

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
1.5
1.5
```
