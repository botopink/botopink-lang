-module(bp_load_cases_async_block_tail_case@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__load'/1, '__bp_priv__run'/0]).

%%% Decision 525 — a `case` at the end of an `async { … }` block is its tail:

%%% the task's value is the arm's, and an arm's `throw` fails the task. The

%%% `case` was a statement, so the succeeding task answered no value: erlang

%%% raised `case_clause`, commonJS printed `null`, wasm `0` and beam `-1`.

%% @Async — eager lowering
load(N) ->
    case (N < 0) of
        true ->
            {error, <<"negative ", ('__bp_text'(erlang:integer_to_binary(N)))/binary>>};
        _ ->
            {ok, N}
    end.

%% @Async — eager lowering
run() ->
    Bad = (fun() ->
        case load((-7)) of
            {error, E} ->
                {error, <<"wrapped: ", ('__bp_text'(E))/binary>>};
            {ok, V} ->
                {ok, '__bp_int'((V * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:17:24">>)}
        end
    end)(),
    B = case Bad of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            (-1)
    end,
    '__bp_print'([B]),
    Good = (fun() ->
        case load(970) of
            {error, E} ->
                {error, <<"wrapped: ", ('__bp_text'(E))/binary>>};
            {ok, V} ->
                {ok, '__bp_int'((V * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:25:24">>)}
        end
    end)(),
    G = case Good of
        {ok, TryV1} -> TryV1;
        {error, _TryE1} ->
            (-1)
    end,
    '__bp_print'([G]).

main() ->
    run().

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/async_block_tail_case|*">>.

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

'__bp_priv__load'(A0) -> load(A0).

'__bp_priv__run'() -> run().
