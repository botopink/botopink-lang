----- SOURCE CODE -- main.bp
```botopink
import {io.terminal.print} from "std";

type Cfg(scoper: ?fn(string) -> string = null, count: ?fn(i32) -> i32 = null, half: ?fn(f64) -> f64 = null)

fn shout(s: string) -> string {
    return s + "!";
}

fn triple(n: i32) -> i32 {
    return n * 3;
}

fn halve(x: f64) -> f64 {
    return x / 2.0;
}

pub fn main() -> void {
    val a = Cfg(scoper: shout);
    print(a.scoper?.("x") ?? "none");
    print(a.count?.(2) ?? -1);
    print(a.half?.(3.0) ?? 0.5);
    val b = Cfg(count: triple, half: halve);
    print(b.scoper?.("y") ?? "none");
    print(b.count?.(0) ?? -1);
    print(b.count?.(2) ?? -1);
    print(b.half?.(3.0) ?? 0.5);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__shout'/1, '__bp_priv__triple'/1, '__bp_priv__halve'/1]).

%% type Cfg: scoper, count, half

shout(S) ->
    <<S/binary, "!">>.

triple(N) ->
    '__bp_int'((N * 3), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:10:14">>).

halve(X) ->
    (X / 2.0).

main() ->
    A = {test@main@@Cfg, fun shout/1, undefined, undefined},
    '__bp_print'([case case erlang:element(2, A) of
        undefined ->
            undefined;
        __bp_opt_19_19 ->
            (__bp_opt_19_19)(<<"x">>)
    end of
        undefined ->
            <<"none">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case case erlang:element(3, A) of
        undefined ->
            undefined;
        __bp_opt_20_18 ->
            (__bp_opt_20_18)(2)
    end of
        undefined ->
            (-1);
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([case case erlang:element(4, A) of
        undefined ->
            undefined;
        __bp_opt_21_17 ->
            (__bp_opt_21_17)(3.0)
    end of
        undefined ->
            0.5;
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    B = {test@main@@Cfg, undefined, fun triple/1, fun halve/1},
    '__bp_print'([case case erlang:element(2, B) of
        undefined ->
            undefined;
        __bp_opt_23_19 ->
            (__bp_opt_23_19)(<<"y">>)
    end of
        undefined ->
            <<"none">>;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    '__bp_print'([case case erlang:element(3, B) of
        undefined ->
            undefined;
        __bp_opt_24_18 ->
            (__bp_opt_24_18)(0)
    end of
        undefined ->
            (-1);
        __bp_nullish@4 ->
            __bp_nullish@4
    end]),
    '__bp_print'([case case erlang:element(3, B) of
        undefined ->
            undefined;
        __bp_opt_25_18 ->
            (__bp_opt_25_18)(2)
    end of
        undefined ->
            (-1);
        __bp_nullish@5 ->
            __bp_nullish@5
    end]),
    '__bp_print'([case case erlang:element(4, B) of
        undefined ->
            undefined;
        __bp_opt_26_17 ->
            (__bp_opt_26_17)(3.0)
    end of
        undefined ->
            0.5;
        __bp_nullish@6 ->
            __bp_nullish@6
    end]).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__shout'(A0) -> shout(A0).

'__bp_priv__triple'(A0) -> triple(A0).

'__bp_priv__halve'(A0) -> halve(A0).
```

----- ERLANG -- test@main@@Cfg.erl
```erlang
-module(test@main@@Cfg).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, scoper) -> erlang:element(2, V);
'__bp_get'(V, count) -> erlang:element(3, V);
'__bp_get'(V, half) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Cfg", [{"scoper", erlang:element(2, V)}, {"count", erlang:element(3, V)}, {"half", erlang:element(4, V)}]}.
```

----- RUN LOG -----
```logs
x!
-1
0.5
none
0
6
1.5
```
