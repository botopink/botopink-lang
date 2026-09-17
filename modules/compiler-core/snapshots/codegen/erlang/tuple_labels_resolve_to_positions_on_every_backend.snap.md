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
-module(main).
-export(['_botopink_main'/0, main/1]).

load() ->
    Name = <<"SP">>,
    Pop = 12,
    {Name, Pop}.

show(R) ->
    element(2, R).

main() ->
    Row = load(),
    '__bp_print'([element(1, Row)]),
    '__bp_print'([(element(2, Row) + 1)]),
    A = <<"RJ">>,
    B = 7,
    Local = {A, B},
    '__bp_print'([element(1, Local)]),
    '__bp_print'([show({<<"BH">>, 3})]),
    '__bp_print'([show(Row)]),
    Typed = {1, 2},
    '__bp_print'([element(2, Typed)]).

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
SP
13
RJ
3
12
2
```
