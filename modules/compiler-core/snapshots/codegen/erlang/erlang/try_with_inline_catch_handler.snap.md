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
    R = case fetch() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    io:format("~p~n", [R]),
    R.

main() ->
    io:format("~p~n", [safe()]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
