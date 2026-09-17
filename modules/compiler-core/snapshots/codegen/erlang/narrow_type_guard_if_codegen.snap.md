----- SOURCE CODE -- main.bp
```botopink
fn isString(x: ?string) -> x is string {
    if (x) { s -> return true; };
    return false;
}
fn main() {
    @print(isString("hello"));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

isString(X) ->
    case X of
        undefined ->
            false;
        S ->
            true
    end.

main() ->
    '__bp_print'([isString(<<"hello">>)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
true
```
