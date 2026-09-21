----- SOURCE CODE -- main.bp
```botopink
fn helper() -> i32 { return 1; }
test "src: in a test" {
    val loc = @src();
    @print(loc.file, loc.line, loc.column, loc.fnName);
}
test {
    @print(@src().fnName);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([main/1]).

%% type SourceLocation: file, line, column, fnName

helper() ->
    1.

'__bp_test_0'() ->
    Loc = #{file => <<"main.bp">>, line => 3, column => 15, fnName => <<"src: in a test">>},
    '__bp_print'([maps:get(file, Loc), maps:get(line, Loc), maps:get(column, Loc), maps:get(fnName, Loc)]).

'__bp_test_1'() ->
    '__bp_print'([maps:get(fnName, #{file => <<"main.bp">>, line => 7, column => 12, fnName => <<"test_1">>})]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

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
        {<<"src: in a test">>, fun '__bp_test_0'/0, <<"main.bp:2">>},
        {<<"test_1">>, fun '__bp_test_1'/0, <<"main.bp:6">>}
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
