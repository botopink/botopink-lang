----- SOURCE CODE -- main.bp
```botopink
val precosBrutos = [100, 250, 400];
val precosComTaxa = loop (precosBrutos) { valor ->
    val taxa = valor * 0.15;
    break valor + taxa;
};
fn main() {
    @print(precosComTaxa);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0]).

precosBrutos() ->
    [100, 250, 400].

precosComTaxa() ->
    case persistent_term:get({main, precosComTaxa}, '__bp_unset') of
        '__bp_unset' -> __BpV = lists:map(fun(Valor) ->
            Taxa = (Valor * 0.15),
            (Valor + Taxa)
        end, precosBrutos()), persistent_term:put({main, precosComTaxa}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

main() ->
    '__bp_print'([precosComTaxa()]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'_botopink_init'() ->
    precosComTaxa(),
    ok.

'_botopink_main'() ->
    '_botopink_init'(),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
[115.0,287.5,460.0]
```
