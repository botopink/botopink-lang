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
-module(test@main).
-export([main/1]).

%% type SourceLocation: file, line, column, fnName

helper() ->
    1.

'__bp_test_0'() ->
    Loc = {test@main@@SourceLocation, <<"main.bp">>, 3, 15, <<"src: in a test">>},
    '__bp_print'([element(2, Loc), element(3, Loc), element(4, Loc), element(5, Loc)]).

'__bp_test_1'() ->
    '__bp_print'([element(5, {test@main@@SourceLocation, <<"main.bp">>, 7, 12, <<"test_1">>})]).

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

'__bp_load_siblings'() ->
    (fun() ->
        Dir = filename:dirname(escript:script_name()),
        Self = atom_to_list(?MODULE) ++ ".erl",
        lists:foreach(fun(Src) ->
            case filename:basename(Src) =:= Self of
                true -> ok;
                false ->
                    case '__bp_prebuilt'(Src) of
                        {ok, Mod, Bin} -> code:load_binary(Mod, Src, Bin);
                        none ->
                            case compile:file(Src, [binary, return_errors, {i, Dir}]) of
                                {ok, Mod, Bin} -> code:load_binary(Mod, Src, Bin);
                                Bad -> '__bp_dead_module'(Src, Bad)
                            end
                    end
            end
        end, filelib:wildcard(filename:join([Dir, "**", "*.erl"])))
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
    halt(1).

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
        L when is_integer(L) -> io_lib:format("~p:", [L]);
        _ -> ""
    end.

main(Args) ->
    '__bp_load_siblings'(),
    Filter = case Args of
        [F | _] -> list_to_binary(F);
        _ -> none
    end,
    '__bp_run_tests'(Filter).
```

----- ERLANG -- test@main@@SourceLocation.erl
```erlang
-module(test@main@@SourceLocation).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, file) -> element(2, V);
'__bp_get'(V, line) -> element(3, V);
'__bp_get'(V, column) -> element(4, V);
'__bp_get'(V, fnName) -> element(5, V).

'__bp_format'(V) -> {record, "SourceLocation", [{"file", element(2, V)}, {"line", element(3, V)}, {"column", element(4, V)}, {"fnName", element(5, V)}]}.
```

----- RUN LOG -----
```logs
```
