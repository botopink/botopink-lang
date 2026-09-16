----- SOURCE CODE -- pond.bp
```botopink
pub record Pato { id: i32 }
```

----- ERLANG -- pond.erl
```erlang
-module(pond).

%% record Pato: id
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {Pato} from "pond";
val Swimmer = interface {
    fn swim(self: Self);
}
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
fn main() {
    val donald = Pato(2);
    @print(donald.swim());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import Pato

%% interface Swimmer

%% implement Swimmer for Pato

swim(Self) ->
    maps:get(id, Self).

main() ->
    Donald = #{id => 2},
    io:format("~p~n", [swim(Donald)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
2
```
