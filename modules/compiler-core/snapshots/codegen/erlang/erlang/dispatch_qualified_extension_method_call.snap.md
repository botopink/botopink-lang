----- SOURCE CODE -- main.bp
```botopink
val Swimmer = interface {
    fn swim(self: Self);
}
record Pato { id: i32 }
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
fn main() {
    val donald = Pato(3);
    @print(PatoNada.swim(donald));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Swimmer

%% record Pato: id

%% implement Swimmer for Pato

swim(Self) ->
    maps:get(id, Self).

main() ->
    Donald = #{id => 3},
    io:format("~p~n", [swim(Donald)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
3
```
