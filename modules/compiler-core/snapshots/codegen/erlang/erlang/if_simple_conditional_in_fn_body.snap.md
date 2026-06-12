----- SOURCE CODE -- main.bp
```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    @print(r);
    return r;
}
fn main() {
    sign(5);
    sign(-3);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

sign(N) ->
    R = case (N > 0) of
        true ->
            <<"positive">>;
        _ -> ok
    end,
    io:format("~p~n", [R]),
    R.

main() ->
    sign(5),
    sign((-3)).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"positive">>
ok
```
