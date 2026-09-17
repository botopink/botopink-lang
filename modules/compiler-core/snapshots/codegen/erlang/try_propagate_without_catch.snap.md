----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn fetch() -> @Result<i32, string> {
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
    erlang:error({todo, <<"not implemented">>}).

process() ->
    case fetch() of
        {ok, R} ->
            '__bp_print'([R]),
            R;
        {error, _TryE0} -> {error, _TryE0}
    end.

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).
```

----- RUN LOG -----
```logs
```
