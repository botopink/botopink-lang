----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val n = -5;
    @print(n.abs());
    @print(n.min(3));
    @print(n.max(10));
    @print(n.clamp(0, 5));
    val x = 7;
    @print(x.isEven());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Number

%% interface Signed

%% interface Integer

main() ->
    N = (-5),
    '__bp_print'([erlang:abs(N)]),
    '__bp_print'([erlang:min(N, 3)]),
    '__bp_print'([erlang:max(N, 10)]),
    '__bp_print'([number_clamp(N, 0, 5)]),
    X = 7,
    '__bp_print'([integer_isEven(X)]).

number_clamp(Self, Lo, Hi) ->
    erlang:min(erlang:max(Self, Lo), Hi).

integer_isEven(Self) ->
    ((Self rem 2) =:= 0).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
5
-5
10
0
false
```
