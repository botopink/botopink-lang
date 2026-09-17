----- SOURCE CODE -- main.bp
```botopink
fn classify(x: ?i32) -> string {
    if (x == 0) { return "zero"; }
    else if (x != 0) { return "nonzero: " + x; }
    else { return "null"; }
}
fn main() {
    @print(classify(42));
    @print(classify(0));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

classify(X) ->
    case (X =:= 0) of
        true ->
            <<"zero">>;
        false ->
            case (X =/= 0) of
                true ->
                    <<"nonzero: ", ('__bp_text'(X))/binary>>;
                false ->
                    <<"null">>
            end
    end.

main() ->
    '__bp_print'([classify(42)]),
    '__bp_print'([classify(0)]).

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
nonzero: 42
zero
```
