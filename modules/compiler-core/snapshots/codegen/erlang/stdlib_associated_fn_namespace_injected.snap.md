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
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export(['__bp_priv__function_identity'/1, '__bp_priv__function_compose'/2, '__bp_priv__function_flip'/1, '__bp_priv__function_constant'/1, '__bp_priv__pair_of'/2, '__bp_priv__pair_first'/1, '__bp_priv__pair_second'/1, '__bp_priv__pair_swap'/1, '__bp_priv__pair_mapFirst'/2, '__bp_priv__pair_mapSecond'/2, '__bp_priv__main'/0]).

%% behavior Function

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

%% behavior Pair

pair_of(First, Second) ->
    {First, Second}.

pair_first(P) ->
    erlang:element(1, P).

pair_second(P) ->
    erlang:element(2, P).

pair_swap(P) ->
    {erlang:element(2, P), erlang:element(1, P)}.

pair_mapFirst(P, Transform) ->
    {Transform(erlang:element(1, P)), erlang:element(2, P)}.

pair_mapSecond(P, Transform) ->
    {erlang:element(1, P), Transform(erlang:element(2, P))}.

main() ->
    P = pair_of(1, <<"one">>),
    '__bp_print'([pair_first(P)]),
    '__bp_print'([function_identity(42)]),
    Inc = function_compose(fun(X) ->
        '__bp_int'((X + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:5:41">>)
    end, fun(Y) ->
        '__bp_int'((Y * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:5:57">>)
    end),
    '__bp_print'([Inc(10)]).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
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

'__bp_priv__function_identity'(A0) -> function_identity(A0).

'__bp_priv__function_compose'(A0, A1) -> function_compose(A0, A1).

'__bp_priv__function_flip'(A0) -> function_flip(A0).

'__bp_priv__function_constant'(A0) -> function_constant(A0).

'__bp_priv__pair_of'(A0, A1) -> pair_of(A0, A1).

'__bp_priv__pair_first'(A0) -> pair_first(A0).

'__bp_priv__pair_second'(A0) -> pair_second(A0).

'__bp_priv__pair_swap'(A0) -> pair_swap(A0).

'__bp_priv__pair_mapFirst'(A0, A1) -> pair_mapFirst(A0, A1).

'__bp_priv__pair_mapSecond'(A0, A1) -> pair_mapSecond(A0, A1).

'__bp_priv__main'() -> main().
```

----- RUN LOG -----
```logs
1
42
22
```
