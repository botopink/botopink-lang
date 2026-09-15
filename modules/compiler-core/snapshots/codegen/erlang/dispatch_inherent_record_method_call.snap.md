----- SOURCE CODE -- main.bp
```botopink
record Contador {
    n: i32,
    fn atual(self: Self) {
        return self.n;
    }
}
fn main() {
    val c = Contador(5);
    @print(c.atual());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record Contador: n

atual(Self) ->
    maps:get(n, Self).

main() ->
    C = #{n => 5},
    io:format("~p~n", [atual(C)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
5
```
