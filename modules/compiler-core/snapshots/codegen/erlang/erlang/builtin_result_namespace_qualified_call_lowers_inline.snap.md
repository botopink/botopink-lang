----- SOURCE CODE -- main.bp
```botopink
*fn parse(n: i32) -> @Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}

fn main() {
    val r = result.map(parse(21), { x -> x * 2 });
    @print(result.unwrap(r, 0));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

parse(N) ->
    case (N < 0) of
        true ->
            {error, <<"negative">>};
        _ ->
            {ok, N}
    end.

main() ->
    R = (fun(R) -> case R of {ok, V} -> {ok, (fun(X) ->
        (X * 2)
    end)(V)}; _ -> R end end)(parse(21)),
    io:format("~p~n", [(fun(R) -> case R of {ok, V} -> V; _ -> (0) end end)(R)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
42
```
