----- SOURCE CODE -- main.bp
```botopink
fn half(n: i32) -> @Result<i32, string> {
    if (n % 2 == 0) {
        return n / 2;
    }
    throw "odd";
}

fn twice(n: i32) -> @Result<i32, string> {
    val h = try half(n);
    return try half(h);
}

fn show(r: @Result<i32, string>) -> string {
    return case r {
        Ok(v) -> "ok " + v;
        Error(e) -> "err " + e;
    };
}

pub fn main() {
    @print(half(4));
    @print(half(3));
    @print(twice(8));
    @print(twice(6));
    @print(show(half(10)));
    @print(show(half(7)));
    @print(half(6).unwrapOr(0));
    @print(half(5).unwrapOr(0));
    @print(half(6).isOk());
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__half'/1, '__bp_priv__twice'/1, '__bp_priv__show'/1]).

half(N) ->
    case ((N rem 2) =:= 0) of
        true ->
            {ok, '__bp_int'((N div 2), -2147483648, 2147483647, <<"integer overflow: / on i32 at main.bp:3:18">>)};
        _ ->
            {error, <<"odd">>}
    end.

twice(N) ->
    case half(N) of
        {ok, H} ->
            half(H);
        {error, _TryE0} -> {error, _TryE0}
    end.

show(R) ->
    case R of
        {ok, V} ->
            <<"ok ", ('__bp_text'(V))/binary>>;
        {error, E} ->
            <<"err ", ('__bp_text'(E))/binary>>
    end.

main() ->
    '__bp_print'([half(4)]),
    '__bp_print'([half(3)]),
    '__bp_print'([twice(8)]),
    '__bp_print'([twice(6)]),
    '__bp_print'([show(half(10))]),
    '__bp_print'([show(half(7))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (0) end end)(half(6))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV1} -> __BpV1; _ -> (0) end end)(half(5))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, _} -> true; _ -> false end end)(half(6))]).

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

'__bp_priv__show'(A0) -> show(A0).
```

----- RUN LOG -----
```logs
Ok(2)
Error("odd")
Ok(2)
Error("odd")
ok 5
err odd
3
0
true
```
