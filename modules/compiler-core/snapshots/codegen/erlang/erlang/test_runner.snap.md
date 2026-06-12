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
    try
        Fun(),
        io:format("  ok   ~s~n", [Name]),
        ok
    catch
        error:{bp_assert, Msg, ALoc} ->
            io:format("  FAIL ~s  (~s)  at ~s~n", [Name, Msg, ALoc]),
            fail;
        Class:Reason ->
            io:format("  FAIL ~s  (~p:~p)  at ~s~n", [Name, Class, Reason, Loc]),
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
    io:format("running ~p tests~n", [length(Selected)]),
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
