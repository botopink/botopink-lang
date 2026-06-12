----- SOURCE CODE -- main.bp
```botopink
record User { name: string }

fn main() {
    val u: ?User = User(name: "ana");
    @print(u?.name);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record User: name

main() ->
    U = #{name => <<"ana">>},
    io:format("~p~n", [(fun(undefined) -> undefined; (_Opt0) -> maps:get(name, _Opt0) end)(U)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"ana">>
```
