----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val a = #(1, "a");
    val b = #(1, "a");
    @print(a == b);
    @print(a != b);
    val c = #(1, "b");
    @print(a == c);
    val name = "SP";
    val pop = 12;
    val labeled = #(name, pop);
    val plain = #("SP", 12);
    @print(labeled == plain);
    val n1 = #(#(1, 2), "x");
    val n2 = #(#(1, 2), "x");
    val n3 = #(#(1, 3), "x");
    @print(n1 == n2);
    @print(n1 == n3);
    val f1 = #(1.5, true);
    val f2 = #(1.5, true);
    val f3 = #(1.5, false);
    @print(f1 == f2);
    @print(f1 == f3);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    A = {1, <<"a">>},
    B = {1, <<"a">>},
    '__bp_print'([(A =:= B)]),
    '__bp_print'([(A =/= B)]),
    C = {1, <<"b">>},
    '__bp_print'([(A =:= C)]),
    Name = <<"SP">>,
    Pop = 12,
    Labeled = {Name, Pop},
    Plain = {<<"SP">>, 12},
    '__bp_print'([(Labeled =:= Plain)]),
    N1 = {{1, 2}, <<"x">>},
    N2 = {{1, 2}, <<"x">>},
    N3 = {{1, 3}, <<"x">>},
    '__bp_print'([(N1 =:= N2)]),
    '__bp_print'([(N1 =:= N3)]),
    F1 = {1.5, true},
    F2 = {1.5, true},
    F3 = {1.5, false},
    '__bp_print'([(F1 =:= F2)]),
    '__bp_print'([(F1 =:= F3)]).

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
true
false
false
true
true
false
true
false
```
