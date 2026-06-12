----- SOURCE CODE -- main.bp
```botopink
*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
fn main() {
    val n = parseAge("42").unwrapOr(0);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

parseAge(S) ->
    erlang:error({todo, "not implemented"}).

main() ->
    N = (fun(R) -> case R of {ok, V} -> V; _ -> (0) end end)(parseAge(<<"42">>)).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
