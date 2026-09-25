----- SOURCE CODE -- main.bp
```botopink
val Inner = type(value: i32)
val Outer = type(inner: ?Inner)
fn getValue(o: Outer) -> ?i32 {
    return o.inner?.value;
}
fn main() {
    val o = Outer(inner: Inner(value: 42));
    @print(getValue(o));
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% type Inner: value

%% type Outer: inner

getValue(O) ->
    (fun(undefined) -> undefined; (_Opt0) -> element(2, _Opt0) end)(element(2, O)).

main() ->
    O = {test@main@@Outer, {test@main@@Inner, 42}},
    '__bp_print'([getValue(O)]).

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

----- ERLANG -- test@main@@Inner.erl
```erlang
-module(test@main@@Inner).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, value) -> element(2, V).

'__bp_format'(V) -> {record, "Inner", [{"value", element(2, V)}]}.
```

----- ERLANG -- test@main@@Outer.erl
```erlang
-module(test@main@@Outer).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, inner) -> element(2, V).

'__bp_format'(V) -> {record, "Outer", [{"inner", element(2, V)}]}.
```

----- RUN LOG -----
```logs
42
```
