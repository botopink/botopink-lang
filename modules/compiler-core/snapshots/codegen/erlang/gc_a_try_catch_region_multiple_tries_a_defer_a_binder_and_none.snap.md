----- SOURCE CODE -- main.bp
```botopink
fn half(n: i32) -> Result<i32, string> {
    if (n % 2 == 0) {
        return n / 2;
    }
    throw "odd";
}

fn twice(n: i32) -> i32 {
    return try {
        defer print("deferred");
        val a = try half(n);
        val b = try half(a);
        b
    } catch { e ->
        print("caught: " + e);
        -1
    };
}

fn unbound(n: i32) -> i32 {
    return try {
        try half(n)
    } catch {
        -99
    };
}

pub fn main() -> void {
    print(twice(8));
    print(twice(3));
    print(unbound(4));
    print(unbound(3));
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__half'/1, '__bp_priv__twice'/1, '__bp_priv__unbound'/1]).

half(N) ->
    case ((N rem 2) =:= 0) of
        true ->
            {ok, '__bp_int'((N div 2), -2147483648, 2147483647, <<"integer overflow: / on i32 at main.bp:3:18">>)};
        _ ->
            {error, <<"odd">>}
    end.

twice(N) ->
    try
        case true of
            _ ->
                try
                    A = case half(N) of
                        {ok, _TryV1} -> _TryV1;
                        {error, _TryE1} -> erlang:throw({'__bp_region', _TryE1})
                    end,
                    B = case half(A) of
                        {ok, _TryV2} -> _TryV2;
                        {error, _TryE2} -> erlang:throw({'__bp_region', _TryE2})
                    end,
                    B
                after
                    '__bp_print'([<<"deferred">>])
                end
        end
    catch
        throw:{'__bp_region', E} -> case true of
            _ ->
                '__bp_print'([<<"caught: ", ('__bp_text'(E))/binary>>]),
                (-1)
        end
    end.

unbound(N) ->
    try
        case true of
            _ ->
                case half(N) of
                    {ok, _TryV1} -> _TryV1;
                    {error, _TryE1} -> erlang:throw({'__bp_region', _TryE1})
                end
        end
    catch
        throw:{'__bp_region', _RgE0} -> case true of
            _ ->
                (-99)
        end
    end.

main() ->
    '__bp_print'([twice(8)]),
    '__bp_print'([twice(3)]),
    '__bp_print'([unbound(4)]),
    '__bp_print'([unbound(3)]).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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
'__bp_show'(V, _) when erlang:is_function(V) -> ["fn/", erlang:integer_to_list(erlang:element(2, erlang:fun_info(V, arity)))];
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

'__bp_priv__half'(A0) -> half(A0).

'__bp_priv__twice'(A0) -> twice(A0).

'__bp_priv__unbound'(A0) -> unbound(A0).
```

----- RUN LOG -----
```logs
deferred
2
deferred
caught: odd
-1
2
-99
```
