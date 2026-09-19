----- SOURCE CODE -- a.bp
```botopink
pub fn twice(x: i32) -> i32 {
    return x * 2;
}
```

----- ERLANG -- a.erl
```erlang
-module(a).
-export([twice/1]).

twice(X) ->
    (X * 2).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- b.bp
```botopink
import { twice };

pub fn quad(x: i32) -> i32 {
    return twice(twice(x));
}

pub fn main() {
    @print(quad(3));
}
```

----- ERLANG -- b.erl
```erlang
-module(b).
-export(['_botopink_main'/0, main/1]).
-export([quad/1, main/0]).

%% import twice

quad(X) ->
    a:twice(a:twice(X)).

main() ->
    '__bp_print'([quad(3)]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
12
```
