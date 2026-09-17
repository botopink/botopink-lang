----- SOURCE CODE -- main.bp
```botopink
val E = record implement @Context<E, E> { tag: string, n: i32 }
fn mk() -> E {
    return E(tag: "x", n: 5);
}
fn main() {
    @print(mk().n);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record E: tag, n

mk() ->
    #{tag => <<"x">>, n => 5}.

main() ->
    '__bp_print'([maps:get(n, mk())]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
5
```
