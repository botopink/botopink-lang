-module(bp_load_cases_fn_tail_case_arm_block@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__classify'/1, '__bp_priv__pick'/1]).

%%% Decision 409 — a function's tail after a `case` bound by a `val`: each arm's

%%% block answers its last statement (front 16), and an arm's value may be a

%%% typed function expression whose own body is a tail (`{ x + 1 }`) or a

%%% lambda; the function answers the `val`.

classify(N) ->
    Label = case N of
        0 ->
            <<"zero">>;
        _ ->
            Sign = case (N < 0) of
                true ->
                    <<"neg">>;
                false ->
                    <<"pos">>
            end,
            '__bp_add'(Sign, erlang:integer_to_binary(N))
    end,
    Label.

pick(N) ->
    F = case N of
        1 ->
            fun(X) ->
                '__bp_int'((X + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:24:35">>)
            end;
        _ ->
            fun(X) ->
                '__bp_int'((X * N), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:27:22">>)
            end
    end,
    F.

main() ->
    '__bp_print'([classify(0)]),
    '__bp_print'([classify((-3))]),
    '__bp_print'([classify(4)]),
    '__bp_print'([(pick(1))(10)]),
    '__bp_print'([(pick(3))(10)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/fn_tail_case_arm_block|*">>.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

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

'__bp_priv__classify'(A0) -> classify(A0).

'__bp_priv__pick'(A0) -> pick(A0).
