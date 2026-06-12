----- SOURCE CODE -- main.bp
```botopink
*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
*fn validate(n: i32) -> @Result<i32, string> { @todo(); }
fn main() {
    val r = parseAge("42")
        .map({ n -> n + 1 })
        .flatMap({ n -> validate(n) })
        .unwrapOr(0);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

parseAge(S) ->
    erlang:error({todo, "not implemented"}).

validate(N) ->
    erlang:error({todo, "not implemented"}).

main() ->
    R = (fun(R) -> case R of {ok, V} -> V; _ -> (0) end end)((fun(R) -> case R of {ok, V} -> (fun(N) ->
        validate(N)
    end)(V); _ -> R end end)((fun(R) -> case R of {ok, V} -> {ok, (fun(N) ->
        (N + 1)
    end)(V)}; _ -> R end end)(parseAge(<<"42">>)))).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
