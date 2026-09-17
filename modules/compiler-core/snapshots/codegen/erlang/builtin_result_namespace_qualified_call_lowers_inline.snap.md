----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn parse(n: i32) -> @Result<i32, string> {
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
    '__bp_print'([(fun(R) -> case R of {ok, V} -> V; _ -> (0) end end)(R)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
42
```
