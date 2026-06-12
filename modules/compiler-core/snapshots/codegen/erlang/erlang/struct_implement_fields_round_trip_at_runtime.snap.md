----- SOURCE CODE -- main.bp
```botopink
val E = struct implement @Context<E, E> { tag: string, n: i32 }
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

%% struct E: tag, n

mk() ->
    #{tag => <<"x">>, n => 5}.

main() ->
    io:format("~p~n", [maps:get(n, mk())]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
5
```
