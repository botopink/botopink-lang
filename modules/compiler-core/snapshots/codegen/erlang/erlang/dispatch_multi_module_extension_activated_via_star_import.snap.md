----- SOURCE CODE -- pond.bp
```botopink
val Swimmer = interface {
    fn swim(self: Self);
}
pub record Pato { id: i32 }
pub val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
```

----- ERLANG -- pond.erl
```erlang
-module(pond).

%% interface Swimmer

%% record Pato: id

%% implement Swimmer for Pato

swim(Self) ->
    maps:get(id, Self).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {Pato, PatoNada*} from "pond";
fn main() {
    val donald = Pato(2);
    @print(donald.swim());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import Pato, PatoNada

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
```
