----- SOURCE CODE -- main.bp
```botopink
fn failing() -> @Result<void, string> {
    throw "boom";
}
fn passing() -> @Result<void, string> {
    return;
}
test "t: fails" {
    try failing();
    @print("not reached");
}
test "t: passes" {
    try passing();
    @print("reached");
}
test "t: a lambda's try is its own" {
    val f = { -> try failing(); 0; };
    @print("still here");
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export([main/1]).

failing() ->
    {error, <<"boom">>}.

passing() ->
    {ok, undefined}.

'__bp_test_0'() ->
    case failing() of
        {ok, _TryV0} ->
            '__bp_print'([<<"not reached">>]);
        {error, _TryE0} -> erlang:error({bp_assert, _TryE0, <<"main.bp:7">>})
    end.

'__bp_test_1'() ->
    case passing() of
        {ok, _TryV0} ->
            '__bp_print'([<<"reached">>]);
        {error, _TryE0} -> erlang:error({bp_assert, _TryE0, <<"main.bp:11">>})
    end.

'__bp_test_2'() ->
    F = fun() ->
        case failing() of
            {ok, _TryV0} ->
                0;
            {error, _TryE0} -> {error, _TryE0}
        end
    end,
    '__bp_print'([<<"still here">>]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'__bp_run_one'({Name, Fun, Loc}) ->
    %% §T `----- RUN LOG -----` envelope (v0.beta.20 frente-b spec):
    %% emit TEST header + fenced ```logs``` block; the test body's
    %% io:format/io:put_chars calls land inside the fence
    %% sequentially via the group leader (no explicit capture
    %% needed for the sync erlang shape).
    io:format("TEST ~s ~s~n", [Loc, Name]),
    io:format("----- RUN LOG -----~n```logs~n", []),
    %% §T duration: monotonic millisecond clock around Fun(); the
    %% delta lands on its own `  duration <ms>ms` line between the
    %% fence close and the ok/FAIL line. Older parsers that don't
    %% recognise the duration line skip it (forward-compatible).
    T0 = erlang:monotonic_time(millisecond),
    Outcome = try
        Fun(),
        ok
    catch
        error:{bp_assert, Msg, ALoc} ->
            {fail, Msg, ALoc};
        Class:Reason ->
            {fail, {Class, Reason}, Loc}
    end,
    T1 = erlang:monotonic_time(millisecond),
    DurMs = erlang:max(0, T1 - T0),
    io:format("```~n", []),
    io:format("  duration ~pms~n", [DurMs]),
    case Outcome of
        ok ->
            io:format("  ok   ~s~n", [Name]),
            ok;
        {fail, FMsg, FLoc} when is_binary(FMsg) ->
            io:format("  FAIL ~s  (~s)  at ~s~n", [Name, FMsg, FLoc]),
            fail;
        {fail, FMsg, FLoc} ->
            io:format("  FAIL ~s  (~p)  at ~s~n", [Name, FMsg, FLoc]),
            fail
    end.

'__bp_run_tests'(Filter) ->
    Tests = [
        {<<"t: fails">>, fun '__bp_test_0'/0, <<"main.bp:7">>},
        {<<"t: passes">>, fun '__bp_test_1'/0, <<"main.bp:11">>},
        {<<"t: a lambda's try is its own">>, fun '__bp_test_2'/0, <<"main.bp:15">>}
    ],
    Selected = case Filter of
        none -> Tests;
        _ -> [T || {N, _, _} = T <- Tests, binary:match(N, Filter) =/= nomatch]
    end,
    Results = ['__bp_run_one'(T) || T <- Selected],
    Failed = length([R || R <- Results, R =:= fail]),
    Passed = length(Results) - Failed,
    io:format("~p passed, ~p failed~n", [Passed, Failed]),
    case Failed > 0 of true -> halt(1); false -> ok end.

main(Args) ->
    Filter = case Args of
        [F | _] -> list_to_binary(F);
        _ -> none
    end,
    '__bp_run_tests'(Filter).
```

----- RUN LOG -----
```logs
```
