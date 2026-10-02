----- SOURCE CODE -- main.bp
```botopink
type Maybe<T> {
    Some(value: T),
    None,
}
fn innerLength(b: unknown) -> i32 {
    return case b {
        Maybe.Some(value: v) when (v is string) { v.length }
        Maybe.Some(value: v) { -1 }
        _ { -2 }
    };
}
fn main() {
    val s: unknown = Maybe.Some(value: "abc");
    @print(innerLength(s));
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% type Maybe
%%   Some(value)
%%   None

innerLength(B) ->
    case B of
        {test@main@@Maybe__v__some, V} when erlang:is_binary(V) ->
            '__bp_len'(V, length);
        {test@main@@Maybe__v__some, V@1} ->
            (-1);
        _ ->
            (-2)
    end.

main() ->
    S = {test@main@@Maybe__v__some, <<"abc">>},
    '__bp_print'([innerLength(S)]).

'__bp_len'(X, _) when erlang:is_list(X) -> erlang:length(X);
'__bp_len'(X, _) when erlang:is_binary(X) -> string:length(X);
'__bp_len'(X, Field) -> maps:get(Field, X).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- ERLANG -- test@main@@Maybe.erl
```erlang
-module(test@main@@Maybe).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@Maybe__v__some, F0}) -> {variant, "Maybe.Some", [{"value", F0}]};
'__bp_format'(test@main@@Maybe__v__none) -> {variant, "Maybe.None", []}.
```

----- RUN LOG -----
```logs
3
```
