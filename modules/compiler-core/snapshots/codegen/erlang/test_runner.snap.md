----- SOURCE CODE -- main.bp
```botopink
fn add(a: i32, b: i32) -> i32 {
    return a + b;
}

test "addition works" {
    val r = add(2, 3);
    assert r == 5;
}

test {
    assert true;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([main/1]).

add(A, B) ->
    (A + B).

'__bp_test_0'() ->
    R = add(2, 3),
    case ((R =:= 5)) of true -> ok; _ -> erlang:error({bp_assert, <<"assertion failed">>, <<"main.bp:7">>}) end.

'__bp_test_1'() ->
    case (true) of true -> ok; _ -> erlang:error({bp_assert, <<"assertion failed">>, <<"main.bp:11">>}) end.

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
        {<<"addition works">>, fun '__bp_test_0'/0, <<"main.bp:5">>},
        {<<"test_1">>, fun '__bp_test_1'/0, <<"main.bp:10">>}
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
