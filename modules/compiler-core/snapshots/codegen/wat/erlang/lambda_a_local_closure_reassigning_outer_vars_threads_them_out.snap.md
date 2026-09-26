----- SOURCE CODE -- main.bp
```botopink
fn render(words: Array<string>) -> string {
    var out = "";
    var count = 0;
    val emit = { w ->
        out = out + "<" + w + ">";
        count = count + 1;
    };
    emit("start");
    for (words) { w -> emit(w); };
    return out + " " + count.toString();
}
fn main() {
    @print(render(["a", "b"]));
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

render(Words) ->
    Out = <<"">>,
    Count = 0,
    Emit = fun(W, {Out@1, Count@1}) ->
        Out@2 = <<Out@1/binary, "<", ('__bp_text'(W))/binary, ">">>,
        Count@2 = (Count@1 + 1),
        {Out@2, Count@2}
    end,
    {Out@3, Count@3} = Emit(<<"start">>, {Out, Count}),
    {Out@6, Count@6} = lists:foldl(fun(W, {Out@4, Count@4}) ->
        {Out@5, Count@5} = Emit(W, {Out@4, Count@4}),
        {Out@5, Count@5}
    end, {Out@3, Count@3}, Words),
    <<Out@6/binary, " ", ('__bp_text'(erlang:integer_to_binary(Count@6)))/binary>>.

main() ->
    '__bp_print'([render([<<"a">>, <<"b">>])]).

'__bp_text'(Value) when is_binary(Value) -> Value;
'__bp_text'(Value) -> iolist_to_binary(io_lib:format(<<"~p">>, [Value])).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
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
<start><a><b> 3
```
