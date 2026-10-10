----- SOURCE CODE -- main.bp
```botopink
fn count(limit: i32) -> i32 {
    var i = 0;
    var acc = "";
    while (i < limit) {
        acc = acc + i.toString();
        i = i + 1;
    };
    @print(acc);
    return i;
}
fn evens(limit: i32) -> i32 {
    var i = 0;
    var sum = 0;
    while (i < limit) {
        i = i + 1;
        if (i % 2 == 1) { continue; };
        sum = sum + i;
    };
    return sum;
}
fn main() {
    @print(count(4));
    @print(count(0));
    @print(evens(6));
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

count(Limit) ->
    I = 0,
    Acc = <<"">>,
    {Acc@3, I@3} = (fun __BpLoop({Acc@1, I@1}) ->
        case (I@1 < Limit) of
            true ->
                Acc@2 = <<Acc@1/binary, ('__bp_text'(erlang:integer_to_binary(I@1)))/binary>>,
                I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:6:15">>),
                __BpLoop({Acc@2, I@2});
            _ -> {Acc@1, I@1}
        end
    end)({Acc, I}),
    '__bp_print'([Acc@3]),
    I@3.

evens(Limit) ->
    I = 0,
    Sum = 0,
    {I@3, Sum@3} = (fun __BpLoop({I@1, Sum@1}) ->
        case (I@1 < Limit) of
            true ->
                __BpLoop(try
                    I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:15:15">>),
                    case ((I@2 rem 2) =:= 1) of
                        true ->
                            erlang:throw({'__bp_cond_continue', {I@2, Sum@1}});
                        _ -> ok
                    end,
                    Sum@2 = '__bp_int'((Sum@1 + I@2), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:17:19">>),
                    {I@2, Sum@2}
                catch
                    throw:{'__bp_cond_continue', __BpGroup2} -> __BpGroup2
                end);
            _ -> {I@1, Sum@1}
        end
    end)({I, Sum}),
    Sum@3.

main() ->
    '__bp_print'([count(4)]),
    '__bp_print'([count(0)]),
    '__bp_print'([evens(6)]).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> erlang:iolist_to_binary(io_lib:format(<<"~p">>, [Value])).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
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
```

----- RUN LOG -----
```logs
0123
4

0
12
```
