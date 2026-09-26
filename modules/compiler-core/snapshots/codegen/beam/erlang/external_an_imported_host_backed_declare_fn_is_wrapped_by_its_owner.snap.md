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
-module(test@hostlib).
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
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0]).

%% import hostKey, hostLen, nodeOnly

main() ->
    '__bp_print'([test@hostlib:hostKey(42)]),
    '__bp_print'([test@hostlib:hostLen([<<"a">>, <<"b">>])]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

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
