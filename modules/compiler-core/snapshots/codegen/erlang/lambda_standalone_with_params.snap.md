----- SOURCE CODE -- main.bp
```botopink
val add = { x, y ->
    x + y;
};
val result = add(10, 20);
fn main() {
    @print(result);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).



main() ->
    io:format("~p~n", [Result]).

'_botopink_main'() ->
    Add = fun(X, Y) ->
        (X + Y)
    end,
    Result = add(10, 20),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
COMPILE ERROR (erlc):
main.erl:7:24: variable 'Result' is unbound
main.erl:13:14: function add/2 undefined
```
