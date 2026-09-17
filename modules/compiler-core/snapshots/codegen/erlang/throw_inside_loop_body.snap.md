----- SOURCE CODE -- main.bp
```botopink
#[@result]
fn validate(items: i32) -> @Result<i32, string> {
    loop (0..items) { i ->
        if (i > 2) { throw "too many"; };
    };
    return items;
}
fn main() {
    @print(validate(2).isOk());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

validate(Items) ->
    lists:foreach(fun(I) ->
        case (I > 2) of
            true ->
                {error, <<"too many">>};
            _ -> ok
        end
    end, lists:seq(0, (Items) - 1)),
    {ok, Items}.

main() ->
    '__bp_print'([(fun(R) -> case R of {ok, _} -> true; _ -> false end end)(validate(2))]).

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
