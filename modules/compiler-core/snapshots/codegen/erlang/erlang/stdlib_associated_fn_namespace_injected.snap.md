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
    io:format("~p~n", [pair_first(P)]),
    io:format("~p~n", [function_identity(42)]),
    Inc = function_compose(fun(X) ->
        (X + 1)
    end, fun(Y) ->
        (Y * 2)
    end),
    io:format("~p~n", [Inc(10)]).

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
