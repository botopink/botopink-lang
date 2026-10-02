----- SOURCE CODE -- main.bp
```botopink
fn load() -> #(name: string, pop: i32) {
    val name = "SP";
    val pop = 12;
    return #(name, pop);
}

fn show(r: #(city: string, pop: i32)) -> i32 {
    return r.pop;
}

fn main() {
    val row = load();
    @print(row.name);
    @print(row.pop + 1);
    val a = "RJ";
    val b = 7;
    val local = #(a, b);
    @print(local.a);
    @print(show(#("BH", 3)));
    @print(show(row));
    val typed: #(x: i32, y: i32) = #(1, 2);
    @print(typed.y);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

load() ->
    Name = <<"SP">>,
    Pop = 12,
    {Name, Pop}.

show(R) ->
    erlang:element(2, R).

main() ->
    Row = load(),
    '__bp_print'([erlang:element(1, Row)]),
    '__bp_print'([(erlang:element(2, Row) + 1)]),
    A = <<"RJ">>,
    B = 7,
    Local = {A, B},
    '__bp_print'([erlang:element(1, Local)]),
    '__bp_print'([show({<<"BH">>, 3})]),
    '__bp_print'([show(Row)]),
    Typed = {1, 2},
    '__bp_print'([erlang:element(2, Typed)]).

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
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
SP
13
RJ
3
12
2
```
