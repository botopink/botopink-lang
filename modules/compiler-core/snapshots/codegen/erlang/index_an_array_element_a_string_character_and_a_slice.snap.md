----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val xs = [10, 20, 30];
    val i = 1;
    @print(xs[0]);
    @print(xs[i + 1]);
    val names = ["ana", "bo"];
    @print(names[1]);
    val s = "hello";
    @print(s[1]);
    @print(s[1..3]);
    @print(s[3..]);
    @print(xs[1..]);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% behavior String

%% behavior Array

array_range(Start, Stop) ->
    case (Start >= Stop) of
        true ->
            [];
        false ->
            Head = Start,
            [Head] ++ (array_range((Start + 1), Stop))
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Head = Value,
            [Head] ++ (array_repeat(Value, (Times - 1)))
    end.

main() ->
    Xs = [10, 20, 30],
    I = 1,
    '__bp_print'([(fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(Xs, 0)]),
    '__bp_print'([(fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(Xs, (I + 1))]),
    Names = [<<"ana">>, <<"bo">>],
    '__bp_print'([(fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(Names, 1)]),
    S = <<"hello">>,
    '__bp_print'([(fun(__S, __I) -> case (__I >= 0) andalso (__I < string:length(__S)) of true -> string:slice(__S, __I, 1); false -> undefined end end)(S, 1)]),
    '__bp_print'([string_slice(S, 1, 3)]),
    '__bp_print'([string_slice(S, 3, undefined)]),
    '__bp_print'([array_slice(Xs, 1, undefined)]).

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            string:slice(Self, Start, ((End) - (Start)));
        false ->
            string:slice(Self, Start)
    end.

array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.

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
10
30
bo
e
el
lo
[20, 30]
```
