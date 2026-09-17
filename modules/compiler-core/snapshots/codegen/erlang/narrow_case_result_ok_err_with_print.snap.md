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
        {ok, V} ->
            <<"OK:", ('__bp_text'(V))/binary>>;
        {error, E} ->
            <<"ERR:", ('__bp_text'(E))/binary>>
    end,
    '__bp_print'([Msg1]),
    R2 = fetch(false),
    Msg2 = case R2 of
        {ok, V@1} ->
            <<"OK:", ('__bp_text'(V@1))/binary>>;
        {error, E@1} ->
            <<"ERR:", ('__bp_text'(E@1))/binary>>
    end,
    '__bp_print'([Msg2]).

'__bp_text'(Value) when is_binary(Value) -> Value;
'__bp_text'(Value) -> iolist_to_binary(io_lib:format(<<"~p">>, [Value])).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
OK:data
ERR:fail
```
