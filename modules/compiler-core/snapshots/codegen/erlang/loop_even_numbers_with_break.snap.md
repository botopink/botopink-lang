----- SOURCE CODE -- main.bp
```botopink
val processamento = loop (0..10) { i ->
    if (i % 2 == 0) {
        break i;
    };
};
fn main() {
    @print(processamento);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

processamento() ->
    lists:filtermap(fun(I) ->
        case ((I rem 2) =:= 0) of
            true ->
                {true, I};
            _ -> false
        end
    end, lists:seq(0, (10) - 1)).

main() ->
    '__bp_print'([processamento()]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
[0,2,4,6,8]
```
