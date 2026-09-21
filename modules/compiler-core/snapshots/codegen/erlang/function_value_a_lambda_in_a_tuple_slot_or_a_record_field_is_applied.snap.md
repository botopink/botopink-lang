----- SOURCE CODE -- main.bp
```botopink
type Ops(step: fn(n: i32) -> i32)
fn mk() -> #(value: i32, set: fn(n: i32) -> i32) {
    val value = 1;
    val set = { n -> return n * 2; };
    return #(value, set);
}
fn main() {
    val c = mk();
    @print(c.value);
    @print(c.set(9));
    val t = #(1, { n -> return n + 100; });
    @print(t._1(2));
    val o = Ops(step: { n -> return n - 1; });
    @print(o.step(10));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% type Ops: step

mk() ->
    Value = 1,
    Set = fun(N) ->
        (N * 2)
    end,
    {Value, Set}.

main() ->
    C = mk(),
    '__bp_print'([element(1, C)]),
    '__bp_print'([element(2, C)(9)]),
    T = {1, fun(N) ->
        (N + 100)
    end},
    '__bp_print'([element(2, T)(2)]),
    O = {main__t__ops, fun(N) ->
        (N - 1)
    end},
    '__bp_print'([(element(2, O))(10)]).

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

----- ERLANG -- main__t__ops.erl
```erlang
-module(main__t__ops).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, step) -> element(2, V).

'__bp_format'(V) -> {record, "Ops", [{"step", element(2, V)}]}.
```

----- RUN LOG -----
```logs
1
18
102
9
```
