----- SOURCE CODE -- main.bp
```botopink
*fn fetch() -> @Result<i32, string> {
    @todo();
}
fn process() -> i32 {
    val r = try fetch();
    @print(r);
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

fetch() ->
    erlang:error({todo, "not implemented"}).

process() ->
    case fetch() of
        {ok, R} ->
            io:format("~p~n", [R]),
            R;
        {error, _TryE0} -> {error, _TryE0}
    end.
```

----- RUN LOG -----
```logs
```
