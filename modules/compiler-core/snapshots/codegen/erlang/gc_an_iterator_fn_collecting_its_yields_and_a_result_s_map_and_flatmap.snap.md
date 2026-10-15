----- SOURCE CODE -- main.bp
```botopink
fn evens(n: i32) -> @Iterator<i32> {
    var i = 0;
    while (i < n) {
        if (i % 2 == 0) yield i;
        i = i + 1;
    }
}

fn parse(s: string) -> @Result<i32, string> {
    if (s == "") throw "empty";
    return s.length();
}

pub fn main() {
    for (evens(7)) { v -> @print(v); }
    @print(parse("abc").map({ n -> n * 10 }).unwrapOr(-1));
    @print(parse("").map({ n -> n * 10 }).unwrapOr(-1));
    @print(parse("ab").flatMap({ n -> parse("xyz") }).unwrapOr(-1));
    @print(parse("ab").flatMap({ n -> parse("") }).isError());
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__evens'/1, '__bp_priv__parse'/1]).

%% @Iterator — eager lowering
evens(N) ->
    __BpGen1 = erlang:make_ref(),
    erlang:put(__BpGen1, []),
    try
        I = 0,
        I@3 = (fun __BpLoop(I@1) ->
            case (I@1 < N) of
                true ->
                    case ((I@1 rem 2) =:= 0) of
                        true ->
                            erlang:put(__BpGen1, [I@1 | erlang:get(__BpGen1)]);
                        _ -> ok
                    end,
                    I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:5:15">>),
                    __BpLoop(I@2);
                _ -> I@1
            end
        end)(I)
    catch
        throw:{'__bp_gen_end', __BpGenK1, _, __BpGenV1} when (__BpGenK1 =:= __BpGen1) -> erlang:put(__BpGen1, [__BpGenV1 | erlang:get(__BpGen1)]), ok
    end,
    lists:reverse(erlang:erase(__BpGen1)).

parse(S) ->
    case (S =:= <<"">>) of
        true ->
            {error, <<"empty">>};
        _ ->
            {ok, erlang:length(unicode:characters_to_list(S))}
    end.

main() ->
    lists:foreach(fun(V) ->
        '__bp_print'([V])
    end, evens(7)),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> ((-1)) end end)((fun(__BpR) -> case __BpR of {ok, __BpV1} -> {ok, (fun(N) ->
        '__bp_int'((N * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:16:38">>)
    end)(__BpV1)}; _ -> __BpR end end)(parse(<<"abc">>)))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV2} -> __BpV2; _ -> ((-1)) end end)((fun(__BpR) -> case __BpR of {ok, __BpV3} -> {ok, (fun(N) ->
        '__bp_int'((N * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:17:35">>)
    end)(__BpV3)}; _ -> __BpR end end)(parse(<<"">>)))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV4} -> __BpV4; _ -> ((-1)) end end)((fun(__BpR) -> case __BpR of {ok, __BpV5} -> (fun(N) ->
        parse(<<"xyz">>)
    end)(__BpV5); _ -> __BpR end end)(parse(<<"ab">>)))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {error, _} -> true; _ -> false end end)((fun(__BpR) -> case __BpR of {ok, __BpV7} -> (fun(N) ->
        parse(<<"">>)
    end)(__BpV7); _ -> __BpR end end)(parse(<<"ab">>)))]).

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

'__bp_priv__evens'(A0) -> evens(A0).

'__bp_priv__parse'(A0) -> parse(A0).
```

----- RUN LOG -----
```logs
0
2
4
6
30
-1
3
true
```
