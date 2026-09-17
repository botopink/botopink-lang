----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn fetch() -> @Result<i32, string> {
    @todo();
}
fn safe() -> i32 {
    val r = try fetch() catch 0;
    @print(r);
    return r;
}
fn main() {
    @print(safe());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

fetch() ->
    erlang:error({todo, <<"not implemented">>}).

safe() ->
    R = case try
        fetch()
    catch
        error:_TryR0 -> {error, _TryR0}
    end of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    '__bp_print'([R]),
    R.

main() ->
    '__bp_print'([safe()]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
0
0
```
