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
-module(test@main).
-export(['__bp_priv__add'/2]).

add(A, B) ->
    '__bp_int'((A + B), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:2:14">>).



-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_priv__add'(A0, A1) -> add(A0, A1).
```

----- ERLANG TEST UNIT -- __test__@test@main.erl
```erlang
-module('__test__@test@main').
-export([main/1]).

'__bp_test_0'() ->
    R = test@main:'__bp_priv__add'(2, 3),
    case ((R =:= 5)) of true -> ok; _ -> erlang:error({bp_assert, <<"assertion failed">>, <<"main.bp:7">>, <<"assertion failed: r == 5 at main.bp:7:5">>}) end.

'__bp_test_1'() ->
    case (true) of true -> ok; _ -> erlang:error({bp_assert, <<"assertion failed">>, <<"main.bp:11">>, <<"assertion failed: true at main.bp:11:5">>}) end.

'__bp_run_one'({Name, Fun, Loc}) ->
    %% §T `----- RUN LOG -----` envelope (v0.beta.20 frente-b spec):
    %% emit TEST header + fenced ```logs``` block; the test body's
    %% io:format/io:put_chars calls land inside the fence
    %% sequentially via the group leader (no explicit capture
    %% needed for the sync erlang shape).
    io:format("TEST ~ts ~ts~n", [Loc, Name]),
    io:format("----- RUN LOG -----~n```logs~n", []),
    %% §T duration: monotonic millisecond clock around Fun(); the
    %% delta lands on its own `  duration <ms>ms` line between the
    %% fence close and the ok/FAIL line. Older parsers that don't
    %% recognise the duration line skip it (forward-compatible).
    %% The running test's name, a run-time value of the harness
    %% (decision 772): BOTOPINK_TEST_NAME while the body runs.
    os:putenv("BOTOPINK_TEST_NAME", erlang:binary_to_list(Name)),
    T0 = erlang:monotonic_time(millisecond),
    Outcome = try
        Fun(),
        ok
    catch
        error:{bp_assert, Msg, ALoc, _} ->
            {fail, Msg, ALoc};
        error:{bp_assert, Msg, ALoc} ->
            {fail, Msg, ALoc};
        error:{panic, PMsg} when erlang:is_binary(PMsg) ->
            {fail, PMsg, Loc};
        Class:Reason ->
            {fail, {Class, Reason}, Loc}
    end,
    T1 = erlang:monotonic_time(millisecond),
    os:unsetenv("BOTOPINK_TEST_NAME"),
    DurMs = erlang:max(0, T1 - T0),
    io:format("```~n", []),
    io:format("  duration ~pms~n", [DurMs]),
    case Outcome of
        ok ->
            io:format("  ok   ~ts~n", [Name]),
            ok;
        {fail, FMsg, FLoc} when erlang:is_binary(FMsg) ->
            io:format("  FAIL ~ts  (~ts)  at ~ts~n", [Name, FMsg, FLoc]),
            fail;
        {fail, FMsg, FLoc} ->
            io:format("  FAIL ~ts  (~tp)  at ~ts~n", [Name, FMsg, FLoc]),
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
    Failed = erlang:length([R || R <- Results, R =:= fail]),
    Passed = erlang:length(Results) - Failed,
    io:format("~p passed, ~p failed~n", [Passed, Failed]),
    case Failed > 0 of true -> erlang:halt(1); false -> ok end.

'__bp_load_siblings'() ->
    (fun() ->
        Dir = filename:dirname(filename:absname(escript:script_name())),
        Self = erlang:atom_to_list(?MODULE) ++ ".erl",
        Compiled = lists:foldl(fun(Src, Acc) ->
            case filename:basename(Src) =:= Self of
                true -> Acc;
                false ->
                    case '__bp_prebuilt'(Src) of
                        {ok, Mod, Bin} -> [{Mod, Src, Bin} | Acc];
                        none ->
                            case compile:file(Src, [binary, return_errors, {i, Dir}]) of
                                {ok, Mod, Bin} -> [{Mod, Src, Bin} | Acc];
                                Bad -> '__bp_dead_module'(Src, Bad)
                            end
                    end
            end
        end, [], filelib:wildcard(filename:join([Dir, "**", "*.erl"]))),
        '__bp_load_all'(lists:reverse(Compiled))
    end)().

'__bp_prebuilt'(Src) ->
    case file:read_file(filename:rootname(Src) ++ ".beam") of
        {ok, Bin} ->
            case beam_lib:chunks(Bin, []) of
                {ok, {Mod, _}} -> {ok, Mod, Bin};
                _ -> none
            end;
        _ -> none
    end.

'__bp_dead_module'(Src, Bad) ->
    io:format(standard_error,
        "error: ~ts does not compile — refusing to run the tests of ~ts~n",
        [Src, escript:script_name()]),
    case Bad of
        {error, Errors, _Warnings} ->
            lists:foreach(fun({File, Ds}) ->
                lists:foreach(fun(D) ->
                    io:format(standard_error, "  ~ts:~ts~n", [File, '__bp_error_text'(D)])
                end, Ds)
            end, Errors);
        Other ->
            io:format(standard_error, "  ~p~n", [Other])
    end,
    erlang:halt(1).

'__bp_error_text'(D) ->
    case D of
        {Loc, Mod, Desc} ->
            io_lib:format("~ts ~ts", ['__bp_error_loc'(Loc),
                try Mod:format_error(Desc) catch _:_ -> io_lib:format("~p", [Desc]) end]);
        Other ->
            io_lib:format(" ~p", [Other])
    end.

'__bp_error_loc'(Loc) ->
    case Loc of
        {L, C} -> io_lib:format("~p:~p:", [L, C]);
        L when erlang:is_integer(L) -> io_lib:format("~p:", [L]);
        _ -> ""
    end.

'__bp_load_all'(Pending) ->
    case [P || {Mod, Src, Bin} = P <- Pending, code:load_binary(Mod, Src, Bin) =/= {module, Mod}] of
        [] -> ok;
        Failed when erlang:length(Failed) < erlang:length(Pending) -> '__bp_load_all'(Failed);
        _ -> ok
    end.

main(Args) ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '__bp_load_siblings'(),
    Filter = case Args of
        [F | _] -> erlang:list_to_binary(F);
        _ -> none
    end,
    '__bp_run_tests'(Filter).
```

----- RUN LOG -----
```logs
```
