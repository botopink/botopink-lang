----- SOURCE CODE -- main.bp
```botopink
*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
fn main() {
    val r = parseAge("42");
    val ok = r.isOk();
    val bad = r.isError();
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

parseAge(S) ->
    erlang:error({todo, "not implemented"}).

main() ->
    R = parseAge(<<"42">>),
    Ok = (fun(R) -> case R of {ok, _} -> true; _ -> false end end)(R),
    Bad = (fun(R) -> case R of {error, _} -> true; _ -> false end end)(R).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
