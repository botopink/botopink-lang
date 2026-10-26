-module(bp_load_cases_task_resumes_in_place@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__check'/1, '__bp_priv__sumTo'/2, '__bp_priv__classify'/1, '__bp_priv__loopy'/0, '__bp_priv__fallible'/0, '__bp_priv__recovered'/0, '__bp_priv__show'/1, '__bp_priv__run'/0]).

%%% Decision 392 (2) — on wasm an asynchronous function is a resumable state

%%% machine: its locals live in a frame across each `await`, and loops, `if`

%%% arms, `try`, `try … catch`, a `case` after an `await`, a method answering

%%% `Async`, a generic function and an `async { }` block that suspend (on a

%%% real timer) are resumed where they stopped. The answers equal commonJS's,

%%% erlang's and beam's.

%% external fn delay -> erlang template

%% type Counter: base

%% @Async — eager lowering
check(N) ->
    V = (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(1, N),
    case (V < 0) of
        true ->
            {error, <<"negative ", ('__bp_text'(erlang:integer_to_binary(V)))/binary>>};
        _ ->
            {ok, '__bp_int'((V * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:27:14">>)}
    end.

%% @Async — eager lowering
sumTo(Xs, F) ->
    Total = 0,
    Total@3 = lists:foldl(fun(X, Total@1) ->
        Got = F(X),
        Total@2 = '__bp_int'((Total@1 + Got), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:34:23">>),
        Total@2
    end, Total, Xs),
    Total@3.

%% @Async — eager lowering
classify(N) ->
    case (N =:= 1) of
        true ->
            W = (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(2, <<"one">>),
            <<('__bp_text'(W))/binary, "!">>;
        _ ->
            Label = case N of
                0 ->
                    <<"zero">>;
                _ ->
                    <<"many">>
            end,
            Label
    end.

%% @Async — eager lowering
loopy() ->
    Out = <<"">>,
    I = 0,
    {Out@3, I@3} = (fun __BpLoop({Out@1, I@1}) ->
        case (I@1 < 3) of
            true ->
                C = (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(1, I@1),
                Out@2 = <<Out@1/binary, ('__bp_text'(erlang:integer_to_binary(C)))/binary>>,
                I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:57:15">>),
                __BpLoop({Out@2, I@2});
            _ -> {Out@1, I@1}
        end
    end)({Out, I}),
    Out@8 = lists:foldl(fun(K, Out@4) ->
        Out@7 = case (K =:= 1) of
            true ->
                S = (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(1, <<"k">>),
                Out@5 = <<Out@4/binary, ('__bp_text'(S))/binary>>,
                Out@5;
            _ ->
                Out@6 = <<Out@4/binary, "-">>,
                Out@6
        end,
        Out@7
    end, Out@3, lists:seq(0, (2) - 1)),
    Out@8.

%% @Async — eager lowering
fallible() ->
    case check(2) of
        {ok, A} ->
            case check((-3)) of
                {ok, B} ->
                    {ok, <<"unreachable ", ('__bp_text'(erlang:integer_to_binary(A)))/binary, ('__bp_text'(erlang:integer_to_binary(B)))/binary>>};
                {error, _TryE1} -> {error, _TryE1}
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

%% @Async — eager lowering
recovered() ->
    R = case check((-1)) of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            7
    end,
    R.

show(R) ->
    case R of
        {ok, V} ->
            '__bp_print'([<<"ok ", ('__bp_text'(V))/binary>>]);
        {error, E} ->
            '__bp_print'([<<"error ", ('__bp_text'(E))/binary>>])
    end.

%% @Async — eager lowering
run() ->
    C = {bp_load_cases_task_resumes_in_place@main@@Counter, 40},
    '__bp_print'([bp_load_cases_task_resumes_in_place@main@@Counter:bump(C, 2)]),
    Checked = check(4),
    case Checked of
        {ok, V} ->
            '__bp_print'([<<"ok ", ('__bp_text'(erlang:integer_to_binary(V)))/binary>>]);
        {error, E} ->
            '__bp_print'([<<"error ", ('__bp_text'(E))/binary>>])
    end,
    show(fallible()),
    '__bp_print'([recovered()]),
    '__bp_print'([sumTo([1, 2, 3], fun(X) ->
        (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(1, '__bp_int'((X * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:96:52">>))
    end)]),
    '__bp_print'([classify(0)]),
    '__bp_print'([classify(1)]),
    '__bp_print'([classify(5)]),
    '__bp_print'([loopy()]),
    T = (fun() ->
        X = (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(3, 5),
        '__bp_int'((X + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:103:18">>)
    end)(),
    '__bp_print'([T]).

main() ->
    run().

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/task_resumes_in_place|*">>.

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
    '__bp_load_siblings'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_load_siblings'() ->
    case code:which(?MODULE) of
        Path when erlang:is_list(Path) ->
            lists:foreach(fun(Src) ->
                case code:ensure_loaded(erlang:list_to_atom(filename:basename(Src, ".erl"))) of
                    {module, _} -> ok;
                    _ ->
                        case compile:file(Src, [binary, return_errors]) of
                            {ok, Mod, Bin} -> code:load_binary(Mod, Src, Bin);
                            Bad ->
                                io:format(standard_error, "error: ~ts does not compile - refusing to run~n  ~p~n", [Src, Bad]),
                                erlang:halt(1)
                        end
                end
            end, filelib:wildcard(filename:join(filename:dirname(Path), "*.erl")));
        _ -> ok
    end.

'__bp_priv__check'(A0) -> check(A0).

'__bp_priv__sumTo'(A0, A1) -> sumTo(A0, A1).

'__bp_priv__classify'(A0) -> classify(A0).

'__bp_priv__loopy'() -> loopy().

'__bp_priv__fallible'() -> fallible().

'__bp_priv__recovered'() -> recovered().

'__bp_priv__show'(A0) -> show(A0).

'__bp_priv__run'() -> run().
