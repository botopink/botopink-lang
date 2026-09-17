----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val p = Pair.of(1, "one");
    @print(Pair.first(p));
    @print(Function.identity(42));
    val inc = Function.compose({ x -> x + 1 }, { y -> y * 2 });
    @print(inc(10));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Function

function_identity(X) ->
    X.

function_compose(F, G) ->
    fun(A) ->
        G(F(A))
    end.

function_flip(F) ->
    fun(B, A) ->
        F(A, B)
    end.

function_constant(X) ->
    fun(Ignored) ->
        X
    end.

%% interface Pair

pair_of(First, Second) ->
    {First, Second}.

pair_first(P) ->
    element(1, P).

pair_second(P) ->
    element(2, P).

pair_swap(P) ->
    {element(2, P), element(1, P)}.

pair_mapFirst(P, Transform) ->
    {Transform(element(1, P)), element(2, P)}.

pair_mapSecond(P, Transform) ->
    {element(1, P), Transform(element(2, P))}.

main() ->
    P = pair_of(1, <<"one">>),
    '__bp_print'([pair_first(P)]),
    '__bp_print'([function_identity(42)]),
    Inc = function_compose(fun(X) ->
        (X + 1)
    end, fun(Y) ->
        (Y * 2)
    end),
    '__bp_print'([Inc(10)]).

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
1
42
22
```
