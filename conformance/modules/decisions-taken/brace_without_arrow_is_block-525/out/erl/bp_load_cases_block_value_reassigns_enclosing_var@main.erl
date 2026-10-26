-module(bp_load_cases_block_value_reassigns_enclosing_var@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decision 525 — a block used as a value that reassigns `var`s of the

%%% enclosing function: the reassignments are visible after the block, and the

%%% block's value is its tail — from the body's end, from an `if` / `else` at

%%% its end and after a loop. On erlang a block that was a fun could not

%%% rebind what it captured.

main() ->
    Acc = 1,
    Label = <<"a">>,
    R = erlang:element(1, {_, {Acc@2, Label@2}} = case true of
        _ ->
            Acc@1 = '__bp_int'((Acc + 10), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:13:19">>),
            Label@1 = <<Label/binary, "b">>,
            __BpArmV1 = '__bp_int'((Acc@1 * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:15:13">>),
            {__BpArmV1, {Acc@1, Label@1}}
    end),
    '__bp_print'([Acc@2, Label@2, R]),
    S = erlang:element(1, {_, Acc@5} = case true of
        _ ->
            case (Acc@2 > 5) of
                true ->
                    Acc@3 = '__bp_int'((Acc@2 - 5), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:21:23">>),
                    __BpArmV2 = <<"big">>,
                    {__BpArmV2, Acc@3};
                _ ->
                    Acc@4 = 0,
                    __BpArmV3 = <<"small">>,
                    {__BpArmV3, Acc@4}
            end
    end),
    '__bp_print'([Acc@5, S]),
    T = erlang:element(1, {_, Acc@9} = case true of
        _ ->
            Acc@8 = lists:foldl(fun(X, Acc@6) ->
                Acc@7 = '__bp_int'((Acc@6 + X), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:32:23">>),
                Acc@7
            end, Acc@5, [1, 2]),
            __BpArmV4 = '__bp_int'((Acc@8 * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:34:13">>),
            {__BpArmV4, Acc@8}
    end),
    '__bp_print'([Acc@9, T]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/block_value_reassigns_enclosing_var|*">>.

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
