----- SOURCE CODE -- hostlib.bp
```botopink
#[@External.Node("String($0)"),
  @External.Erlang("""iolist_to_binary(io_lib:format("~0tp", [$0]))""")]
pub declare fn hostKey(v: i32) -> string;

#[@External.Node("$0.length"),
  @External.Erlang("erlang", "length")]
pub declare fn hostLen(xs: Array<string>) -> i32;

#[@External.Node("console.log($0)")]
pub declare fn nodeOnly(s: string) -> void;
```

----- ERLANG -- hostlib.erl
```erlang
-module(hostlib).
-export([hostKey/1, hostLen/1]).

%% external fn hostKey -> erlang template
hostKey(V) ->
    iolist_to_binary(io_lib:format("~0tp", [V])).

%% external fn hostLen -> erlang:length
hostLen(Xs) ->
    erlang:length(Xs).

%% external fn nodeOnly (no erlang target)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import { hostKey, hostLen, nodeOnly };

pub fn main() {
    @print(hostKey(42));
    @print(hostLen(["a", "b"]));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).
-export([main/0]).

%% import hostKey, hostLen, nodeOnly

main() ->
    '__bp_print'([hostlib:hostKey(42)]),
    '__bp_print'([hostlib:hostLen([<<"a">>, <<"b">>])]).

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
42
2
```
