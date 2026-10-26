-module(bp_load_cases_task_compose_by_async_block@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__load'/1, '__bp_priv__show'/2, '__bp_priv__run'/0]).

%%% Decision 523 — a task is composed by an `async { … }` block, itself a

%%% `Async` (decision 375), which leaves through `return`: `safe` recovers a failing

%%% task with `try await … catch`, `doubled` maps a task's value, and `chained`

%%% binds one task into another. Every

%%% composition reads the same on every target.

%% @Async — eager lowering
load(N) ->
    case (N < 0) of
        true ->
            {error, <<"negative ", ('__bp_text'(erlang:integer_to_binary(N)))/binary>>};
        _ ->
            {ok, N}
    end.

show(Label, N) ->
    '__bp_print'([<<Label/binary, " ", ('__bp_text'(erlang:integer_to_binary(N)))/binary>>]).

%% @Async — eager lowering
run() ->
    SafeGood = (fun() ->
        V = case load(5) of
            {ok, TryV0} -> TryV0;
            {error, _TryE0} ->
                0
        end,
        V
    end)(),
    SafeBad = (fun() ->
        V = case load((-1)) of
            {ok, TryV1} -> TryV1;
            {error, _TryE1} ->
                0
        end,
        V
    end)(),
    show(<<"safe good">>, SafeGood),
    show(<<"safe bad">>, SafeBad),
    T = load(10),
    Doubled = (fun() ->
        V = case T of
            {ok, TryV2} -> TryV2;
            {error, _TryE2} ->
                0
        end,
        '__bp_int'((V * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:33:18">>)
    end)(),
    show(<<"doubled">>, Doubled),
    Chained = (fun() ->
        case load(3) of
            {ok, First} ->
                case load('__bp_int'((First + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:39:43">>)) of
                    {ok, Second} ->
                        {ok, '__bp_int'((Second * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:40:23">>)};
                    {error, _TryE4} -> {error, _TryE4}
                end;
            {error, _TryE3} -> {error, _TryE3}
        end
    end)(),
    ChainedValue = case Chained of
        {ok, TryV5} -> TryV5;
        {error, _TryE5} ->
            0
    end,
    show(<<"chained">>, ChainedValue).

main() ->
    run().

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/task_compose_by_async_block|*">>.

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

'__bp_priv__show'(A0, A1) -> show(A0, A1).

'__bp_priv__run'() -> run().
