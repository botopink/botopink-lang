----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn fetch(ok: bool) -> @Result<string, string> {
    if (ok) { return "data"; };
    throw "fail";
}
fn main() {
    val r1 = fetch(true);
    val msg1 = case r1 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; };
    @print(msg1);
    val r2 = fetch(false);
    val msg2 = case r2 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; };
    @print(msg2);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

fetch(Ok) ->
    case Ok of
        true ->
            {ok, <<"data">>};
        _ ->
            {error, <<"fail">>}
    end.

main() ->
    R1 = fetch(true),
    Msg1 = case R1 of
        {tag, Ok, V} ->
            (<<"OK:">> + V);
        {tag, Err, E} ->
            (<<"ERR:">> + E)
    end,
    io:format("~p~n", [Msg1]),
    R2 = fetch(false),
    Msg2 = case R2 of
        {tag, Ok, V} ->
            (<<"OK:">> + V);
        {tag, Err, E} ->
            (<<"ERR:">> + E)
    end,
    io:format("~p~n", [Msg2]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
