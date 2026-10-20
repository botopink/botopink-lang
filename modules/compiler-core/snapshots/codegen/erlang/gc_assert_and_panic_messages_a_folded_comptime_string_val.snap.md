----- SOURCE CODE -- main.bp
```botopink
val GREETING = comptime "hi";

fn check(n: i32) -> i32 {
    assert n > 0, "n must be positive";
    return n;
}

pub fn main() -> void {
    print(GREETING);
    print(check(3));
    if (check(1) < 0) {
        panic("negative");
    }
    print("done");
}

import {io.terminal.print, failure.panic} from "std";
```

----- COMPTIME VALUES -- main
```text
ct_0: val GREETING = comptime "hi" → "hi"
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__GREETING'/0, '__bp_priv__check'/1]).

'GREETING'() ->
    <<"hi">>.

check(N) ->
    case ((N > 0)) of true -> ok; _ -> _AssertMsg0 = <<"n must be positive">>, erlang:error({bp_assert, _AssertMsg0, <<"main.bp:4">>, [<<"assertion failed: n > 0: ">>, _AssertMsg0, <<" at main.bp:4:5">>]}) end,
    N.

main() ->
    '__bp_print'(['GREETING'()]),
    '__bp_print'([check(3)]),
    case (check(1) < 0) of
        true ->
            erlang:error({panic, <<"negative">>});
        _ -> ok
    end,
    '__bp_print'([<<"done">>]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__GREETING'() -> 'GREETING'().

'__bp_priv__check'(A0) -> check(A0).
```

----- RUN LOG -----
```logs
hi
3
done
```
