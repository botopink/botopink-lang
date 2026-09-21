----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn inner(should_fail: bool) -> @Result<i32, string> {
    if (should_fail) {
        throw "inner-fail";
    } else {
        return 7;
    }
}
#[@result]
fn outer(should_fail: bool) -> @Result<i32, string> {
    val v = try inner(should_fail);
    return v + 1;
}
fn main() {
    val r = try outer(false) catch -1;
    @print(r);
    val r2 = try outer(true) catch -1;
    @print(r2);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

inner(Should_fail) ->
    case Should_fail of
        true ->
            {error, <<"inner-fail">>};
        false ->
            {ok, 7}
    end.

outer(Should_fail) ->
    case inner(Should_fail) of
        {ok, V} ->
            {ok, (V + 1)};
        {error, _TryE0} -> {error, _TryE0}
    end.

main() ->
    R = case try
        outer(false)
    catch
        error:_TryR0 -> {error, _TryR0}
    end of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            (-1)
    end,
    '__bp_print'([R]),
    R2 = case try
        outer(true)
    catch
        error:_TryR1 -> {error, _TryR1}
    end of
        {ok, TryV1} -> TryV1;
        {error, _TryE1} ->
            (-1)
    end,
    '__bp_print'([R2]).

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
8
-1
```
