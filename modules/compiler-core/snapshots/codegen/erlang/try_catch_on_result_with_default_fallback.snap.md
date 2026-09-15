----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn maybeFail(should_fail: bool) -> @Result<i32, string> {
    if (should_fail) {
        throw "boom";
    } else {
        return 42;
    }
}
fn main() {
    val v = try maybeFail(false) catch -1;
    @print(v);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

maybeFail(Should_fail) ->
    case Should_fail of
        true ->
            {error, <<"boom">>};
        false ->
            {ok, 42}
    end.

main() ->
    V = case maybeFail(false) of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            (-1)
    end,
    io:format("~p~n", [V]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
42
```
