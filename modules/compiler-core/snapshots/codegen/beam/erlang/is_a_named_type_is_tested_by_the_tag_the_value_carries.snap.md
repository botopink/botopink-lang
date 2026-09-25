----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
type Vec(name: string, age: i32)
type Shape { Dot, Circle(radius: i32) }

fn nameOf(v: Person | Vec) -> string {
    return case v {
        Person { "person" }
        Vec { "vec" }
    };
}

fn main() {
    val u: unknown = Vec(name: "Ana", age: 30);
    @print(u is Vec);
    @print(u is Person);
    val s: unknown = Shape.Circle(radius: 4);
    @print(s is Shape);
    val d: unknown = Shape.Dot;
    @print(d is Shape);
    @print(nameOf(Person(name: "Ana", age: 30)));
    @print(nameOf(Vec(name: "Ana", age: 30)));
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% type Person: name, age

%% type Vec: name, age

%% type Shape
%%   Dot
%%   Circle(radius)

nameOf(V) ->
    case V of
        Person when ((is_tuple(Person) andalso (tuple_size(Person) =:= 3)) andalso (element(1, Person) =:= test@main@@Person)) ->
            <<"person">>;
        Vec when ((is_tuple(Vec) andalso (tuple_size(Vec) =:= 3)) andalso (element(1, Vec) =:= test@main@@Vec)) ->
            <<"vec">>
    end.

main() ->
    U = {test@main@@Vec, <<"Ana">>, 30},
    '__bp_print'([((is_tuple(U) andalso (tuple_size(U) =:= 3)) andalso (element(1, U) =:= test@main@@Vec))]),
    '__bp_print'([((is_tuple(U) andalso (tuple_size(U) =:= 3)) andalso (element(1, U) =:= test@main@@Person))]),
    S = {test@main@@Shape__v__circle, 4},
    '__bp_print'([((S =:= test@main@@Shape__v__dot) orelse ((is_tuple(S) andalso (tuple_size(S) =:= 2)) andalso (element(1, S) =:= test@main@@Shape__v__circle)))]),
    D = test@main@@Shape__v__dot,
    '__bp_print'([((D =:= test@main@@Shape__v__dot) orelse ((is_tuple(D) andalso (tuple_size(D) =:= 2)) andalso (element(1, D) =:= test@main@@Shape__v__circle)))]),
    '__bp_print'([nameOf({test@main@@Person, <<"Ana">>, 30})]),
    '__bp_print'([nameOf({test@main@@Vec, <<"Ana">>, 30})]).

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

----- ERLANG -- test@main@@Person.erl
```erlang
-module(test@main@@Person).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> element(2, V);
'__bp_get'(V, age) -> element(3, V).

'__bp_format'(V) -> {record, "Person", [{"name", element(2, V)}, {"age", element(3, V)}]}.
```

----- ERLANG -- test@main@@Vec.erl
```erlang
-module(test@main@@Vec).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> element(2, V);
'__bp_get'(V, age) -> element(3, V).

'__bp_format'(V) -> {record, "Vec", [{"name", element(2, V)}, {"age", element(3, V)}]}.
```

----- ERLANG -- test@main@@Shape.erl
```erlang
-module(test@main@@Shape).
-export(['__bp_format'/1]).

'__bp_format'(test@main@@Shape__v__dot) -> {variant, "Shape.Dot", []};
'__bp_format'({test@main@@Shape__v__circle, F0}) -> {variant, "Shape.Circle", [{"radius", F0}]}.
```

----- RUN LOG -----
```logs
true
false
true
true
person
vec
```
