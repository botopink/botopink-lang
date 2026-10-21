----- SOURCE CODE -- main.bp
```botopink
fn failing() -> Result<void, string> {
    throw "boom";
}
fn passing() -> Result<void, string> {
    return;
}
test "t: fails" {
    try failing();
    print("not reached");
}
test "t: passes" {
    try passing();
    print("reached");
}
test "t: a lambda's try is its own" {
    val f: fn() -> Result<i32, string> = { -> try failing(); return 0; };
    print("still here");
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__failing'/0, '__bp_priv__passing'/0]).

failing() ->
    {error, <<"boom">>}.

passing() ->
    {ok, undefined}.




'__bp_priv__failing'() -> failing().

'__bp_priv__passing'() -> passing().
```

----- ERLANG TEST UNIT -- __test__@test@main.erl
```erlang
-module('__test__@test@main').
-export([main/1]).

'__bp_test_0'() ->
    case test@main:'__bp_priv__failing'() of
        {ok, _TryV0} ->
            '__bp_print'([<<"not reached">>]);
        {error, _TryE0} -> erlang:error({bp_assert, _TryE0, <<"main.bp:7">>})
    end.

'__bp_test_1'() ->
    case test@main:'__bp_priv__passing'() of
        {ok, _TryV0} ->
            '__bp_print'([<<"reached">>]);
        {error, _TryE0} -> erlang:error({bp_assert, _TryE0, <<"main.bp:11">>})
    end.

'__bp_test_2'() ->
    F = fun() ->
        case test@main:'__bp_priv__failing'() of
            {ok, _TryV0} ->
                {ok, 0};
            {error, _TryE0} -> {error, _TryE0}
        end
    end,
    '__bp_print'([<<"still here">>]).

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
        {<<"t: fails">>, fun '__bp_test_0'/0, <<"main.bp:7">>},
        {<<"t: passes">>, fun '__bp_test_1'/0, <<"main.bp:11">>},
        {<<"t: a lambda's try is its own">>, fun '__bp_test_2'/0, <<"main.bp:15">>}
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
