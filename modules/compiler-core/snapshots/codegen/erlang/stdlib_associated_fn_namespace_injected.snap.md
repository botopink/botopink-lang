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
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

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
