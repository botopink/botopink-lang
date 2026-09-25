----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn fetch(ok: bool) -> @Result<string, string> {
    if (ok) { return "data"; };
    throw "fail";
}
fn main() {
    val r1 = fetch(true);
    val msg1 = case r1 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; };
    @print(msg1);
    val r2 = fetch(false);
    val msg2 = case r2 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; };
    @print(msg2);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

fetch(Ok) ->
    case Ok of
        true ->
            {ok, <<"data">>};
        _ ->
            {error, <<"fail">>}
    end.

main() ->
    R1 = fetch(true),
    Msg1 = case R1 of
        {ok, V} ->
            <<"OK:", ('__bp_text'(V))/binary>>;
        {error, E} ->
            <<"ERR:", ('__bp_text'(E))/binary>>
    end,
    '__bp_print'([Msg1]),
    R2 = fetch(false),
    Msg2 = case R2 of
        {ok, V@1} ->
            <<"OK:", ('__bp_text'(V@1))/binary>>;
        {error, E@1} ->
            <<"ERR:", ('__bp_text'(E@1))/binary>>
    end,
    '__bp_print'([Msg2]).

'__bp_text'(Value) when is_binary(Value) -> Value;
'__bp_text'(Value) -> iolist_to_binary(io_lib:format(<<"~p">>, [Value])).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
OK:data
ERR:fail
```
