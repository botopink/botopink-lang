----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn inner(should_fail: bool) -> @Result<i32, string> {
    if (should_fail) {
        throw "inner-fail";
    } else {
        return 7;
    }
}
#[@result]
fn outer(should_fail: bool) -> @Result<i32, string> {
    val v = try inner(should_fail);
    return v + 1;
}
fn main() {
    val r = try outer(false) catch -1;
    @print(r);
    val r2 = try outer(true) catch -1;
    @print(r2);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

inner(Should_fail) ->
    case Should_fail of
        true ->
            {error, <<"inner-fail">>};
        false ->
            {ok, 7}
    end.

outer(Should_fail) ->
    case inner(Should_fail) of
        {ok, V} ->
            {ok, (V + 1)};
        {error, _TryE0} -> {error, _TryE0}
    end.

main() ->
    R = case outer(false) of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            (-1)
    end,
    io:format("~p~n", [R]),
    R2 = case outer(true) of
        {ok, TryV1} -> TryV1;
        {error, _TryE1} ->
            (-1)
    end,
    io:format("~p~n", [R2]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
8
-1
```
