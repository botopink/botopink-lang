-module(effect_annotation_removed_refused_127@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, '__bp_ets_owner'/2, '__bp_loaded'/2, '__bp_load_module'/3, '__bp_run'/1, '__bp_run_async'/1, '__bp_run_none'/0, '__bp_run_async_none'/0, '__bp_executor_0'/0, '__bp_executor_1'/0, '__bp_executor_2'/0, '__bp_executor_3'/0, '__bp_executor_4'/0, '__bp_executor_5'/0, '__bp_executor_6'/0, '__bp_executor_7'/0, '__bp_executor_8'/0, '__bp_executor_9'/0, '__bp_executor_10'/0, '__bp_executor_11'/0, '__bp_executor_12'/0, '__bp_executor_13'/0, '__bp_executor_14'/0, '__bp_executor_15'/0, '__bp_executor_16'/0, '__bp_executor_17'/0, '__bp_executor_18'/0, '__bp_executor_19'/0, '__bp_executor_20'/0, '__bp_executor_21'/0, '__bp_executor_22'/0, '__bp_executor_23'/0, '__bp_executor_24'/0, main/0, accepted/0, '__bp_comptime_0_at'/0, '__bp_init_0'/0, '__bp_init_1'/0, '__bp_init_2'/0, '__bp_init_3'/0, '__bp_init_4'/0, '__bp_init_5'/0, '__bp_init_6'/0, '__bp_init_7'/0, '__bp_init_8'/0, '__bp_init_9'/0, '__bp_init_10'/0, '__bp_init_11'/0, '__bp_init_12'/0, '__bp_init_13'/0, '__bp_init_14'/0, '__bp_init_15'/0, '__bp_init_16'/0, '__bp_init_17'/0, '__bp_init_18'/0, '__bp_init_19'/0, '__bp_init_20'/0, '__bp_init_21'/0, '__bp_init_22'/0, '__bp_init_23'/0, '__bp_init_24'/0, '__bp_priv__answers'/0, '__bp_priv____bp_tab_answers'/0, '__bp_priv__string_slice'/3, '__bp_priv____bp_ets'/2]).

%% import RunFailureKind

%% type Asset: path, bytes, size, hash

%% behavior string

%% import Observed, Refusal

%% import Diagnostic, Module, Refused, __bp_run_attempt

'__bp_loaded'(M, Ds) ->
    case (erlang:length(Ds) > 0) of
        true ->
            {error, {std@compiler@@Refused, M, Ds}};
        _ ->
            {ok, M}
    end.

'__bp_load_module'(Name, Path, BuildOutput) ->
    std@compiler@@Module:'of'(Name, Path, BuildOutput).

%% import RunFailure, __bp_run_failure

'__bp_run'(F) ->
    Open = std@compiler@@Module:captureOpen(),
    Answer = std@failure:attempt(F),
    Output = std@compiler@@Module:captureClose(Open),
    case Answer of
        {ok, Ran} ->
            case Ran of
                {ok, _} ->
                    {ok, Output};
                {error, M} ->
                    case (string:prefix(M, <<"\0bp-off:X">>) =/= nomatch) of
                        true ->
                            {error, {std@compiler@@RunFailure, std@compiler@@RunFailureKind__v__excluded, string_slice(M, 9, undefined), Output}};
                        _ ->
                            case (string:prefix(M, <<"\0bp-off:R">>) =/= nomatch) of
                                true ->
                                    {error, {std@compiler@@RunFailure, std@compiler@@RunFailureKind__v__refused, string_slice(M, 9, undefined), Output}};
                                _ ->
                                    {error, {std@compiler@@RunFailure, std@compiler@@RunFailureKind__v__failed, M, Output}}
                            end
                    end
            end;
        {error, Crash} ->
            {error, {std@compiler@@RunFailure, std@compiler@@RunFailureKind__v__abort, '__bp_field'(Crash, message), Output}}
    end.

%% @Async — eager lowering
'__bp_run_async'(F) ->
    Open = std@compiler@@Module:captureOpen(),
    Answer = std@failure:attemptTask(F),
    Output = std@compiler@@Module:captureClose(Open),
    case Answer of
        {ok, Ran} ->
            case Ran of
                {ok, _} ->
                    {ok, Output};
                {error, M} ->
                    case (string:prefix(M, <<"\0bp-off:X">>) =/= nomatch) of
                        true ->
                            {error, {std@compiler@@RunFailure, std@compiler@@RunFailureKind__v__excluded, string_slice(M, 9, undefined), Output}};
                        _ ->
                            case (string:prefix(M, <<"\0bp-off:R">>) =/= nomatch) of
                                true ->
                                    {error, {std@compiler@@RunFailure, std@compiler@@RunFailureKind__v__refused, string_slice(M, 9, undefined), Output}};
                                _ ->
                                    {error, {std@compiler@@RunFailure, std@compiler@@RunFailureKind__v__failed, M, Output}}
                            end
                    end
            end;
        {error, Crash} ->
            {error, {std@compiler@@RunFailure, std@compiler@@RunFailureKind__v__abort, '__bp_field'(Crash, message), Output}}
    end.

'__bp_run_none'() ->
    {ok, undefined}.

%% @Async — eager lowering
'__bp_run_async_none'() ->
    {ok, undefined}.

%%% A module checking itself (decision 989): each case is a package under `cases/`, loaded at build,

%%% run in this program and compared with its section of `snapshot/main.snap`; a difference writes

%%% `snapshot/main.snap.new` and `main` answers `Error`. Nothing here accepts a candidate.

%% import __bp_ns_adapter__buildOutput, __bp_ns_adapter__frames, __bp_ns_adapter__target, __bp_ns_adapter__ranOf, __bp_ns_candidate__finish, __bp_ns_observe__refusedAnswer, __bp_ns_observe__refusalOf, __bp_ns_observe__ranAnswer

%% The snapshot, read as a build input (decision 989 (5)).

accepted() ->
    <<"botopink-cell 2\n">>.

%% What each case answered, in the order the cases ran.

%% var answers — beamMemory(.Ets)
answers() ->
    std@beam:etsGet('__bp_tab_answers'(), effect_annotation_removed_refused_127@main@@answers, 2).

'__bp_tab_answers'() ->
    case erlang:whereis(effect_annotation_removed_refused_127@main@@answers) of
        undefined -> '__bp_ets'(effect_annotation_removed_refused_127@main@@answers, []);
        _ -> effect_annotation_removed_refused_127@main@@answers
    end.

%% One case, expanded where it is called (decision 808 (2)): a refused load answers its

%% diagnostics, a loaded one runs and answers its output.

'__bp_comptime_0_at'() ->
    0.

'__bp_executor_0'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_async_generator">>, <<"cases/effect_annotation_removed_async_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 8, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_annotation_removed_async_generator">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_async_generator">>, <<"cases/effect_annotation_removed_async_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 8, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))), Refusals@3)])
    end).

'__bp_init_0'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_0'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_0'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_0'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_1'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_context">>, <<"cases/effect_annotation_removed_context">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 11, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_annotation_removed_context">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_context">>, <<"cases/effect_annotation_removed_context">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 11, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))), Refusals@3)])
    end).

'__bp_init_1'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_1'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_1'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_1'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_2'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_future">>, <<"cases/effect_annotation_removed_future">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 7, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_annotation_removed_future">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_future">>, <<"cases/effect_annotation_removed_future">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 7, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))), Refusals@3)])
    end).

'__bp_init_2'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_2'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_2'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_2'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_3'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_future_generator">>, <<"cases/effect_annotation_removed_future_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 6, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_annotation_removed_future_generator">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_future_generator">>, <<"cases/effect_annotation_removed_future_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 6, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))), Refusals@3)])
    end).

'__bp_init_3'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_3'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_3'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_3'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_4'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_future_generator_loop">>, <<"cases/effect_annotation_removed_future_generator_loop">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a loop takes the `iter` / `stream` prefix (decision 125)">>, <<"src/main.bp">>, 10, 15, <<"remove the annotation; write `iter loop` (or `stream loop`)">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_annotation_removed_future_generator_loop">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_future_generator_loop">>, <<"cases/effect_annotation_removed_future_generator_loop">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a loop takes the `iter` / `stream` prefix (decision 125)">>, <<"src/main.bp">>, 10, 15, <<"remove the annotation; write `iter loop` (or `stream loop`)">>, []}]}))), Refusals@3)])
    end).

'__bp_init_4'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_4'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_4'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_4'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_5'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_generator">>, <<"cases/effect_annotation_removed_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 8, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_annotation_removed_generator">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_generator">>, <<"cases/effect_annotation_removed_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 8, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))), Refusals@3)])
    end).

'__bp_init_5'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_5'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_5'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_5'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_6'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_generator_loop">>, <<"cases/effect_annotation_removed_generator_loop">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a loop takes the `iter` / `stream` prefix (decision 125)">>, <<"src/main.bp">>, 11, 15, <<"remove the annotation; write `iter loop` (or `stream loop`)">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_annotation_removed_generator_loop">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_generator_loop">>, <<"cases/effect_annotation_removed_generator_loop">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a loop takes the `iter` / `stream` prefix (decision 125)">>, <<"src/main.bp">>, 11, 15, <<"remove the annotation; write `iter loop` (or `stream loop`)">>, []}]}))), Refusals@3)])
    end).

'__bp_init_6'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_6'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_6'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_6'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_7'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_iterator">>, <<"cases/effect_annotation_removed_iterator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 11, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_annotation_removed_iterator">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_iterator">>, <<"cases/effect_annotation_removed_iterator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 11, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))), Refusals@3)])
    end).

'__bp_init_7'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_7'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_7'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_7'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_8'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_result">>, <<"cases/effect_annotation_removed_result">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 9, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_annotation_removed_result">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_result">>, <<"cases/effect_annotation_removed_result">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 9, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))), Refusals@3)])
    end).

'__bp_init_8'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_8'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_8'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_8'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_9'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_result_generator">>, <<"cases/effect_annotation_removed_result_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 9, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_annotation_removed_result_generator">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_result_generator">>, <<"cases/effect_annotation_removed_result_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 9, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))), Refusals@3)])
    end).

'__bp_init_9'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_9'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_9'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_9'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_10'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_result_generator_loop">>, <<"cases/effect_annotation_removed_result_generator_loop">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a loop takes the `iter` / `stream` prefix (decision 125)">>, <<"src/main.bp">>, 10, 15, <<"remove the annotation; write `iter loop` (or `stream loop`)">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_annotation_removed_result_generator_loop">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_result_generator_loop">>, <<"cases/effect_annotation_removed_result_generator_loop">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a loop takes the `iter` / `stream` prefix (decision 125)">>, <<"src/main.bp">>, 10, 15, <<"remove the annotation; write `iter loop` (or `stream loop`)">>, []}]}))), Refusals@3)])
    end).

'__bp_init_10'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_10'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_10'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_10'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_11'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_use">>, <<"cases/effect_annotation_removed_use">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 7, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_annotation_removed_use">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_annotation_removed_use">>, <<"cases/effect_annotation_removed_use">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-annotation-removed">>, <<"effect annotations were removed \x{E2}\x{80}\x{94} a body marker and its return type say it (decisions 118, 553)">>, <<"src/main.bp">>, 7, 3, <<"remove the annotation; write the marker before `fn` and the wrapper in the return">>, []}]}))), Refusals@3)])
    end).

'__bp_init_11'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_11'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_11'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_11'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_12'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_async_iterator">>, <<"cases/effect_type_removed_async_iterator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"this sequence type left the language (decisions 103, 122)">>, <<"src/main.bp">>, 10, 21, <<"write `AsyncIter<T>`, `Iter<T>` or `YieldStep<T>`">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_type_removed_async_iterator">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_async_iterator">>, <<"cases/effect_type_removed_async_iterator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"this sequence type left the language (decisions 103, 122)">>, <<"src/main.bp">>, 10, 21, <<"write `AsyncIter<T>`, `Iter<T>` or `YieldStep<T>`">>, []}]}))), Refusals@3)])
    end).

'__bp_init_12'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_12'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_12'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_12'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_13'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_future">>, <<"cases/effect_type_removed_future">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"`@Future` was removed \x{E2}\x{80}\x{94} the wrapper is `Async<T>`, which never fails (decision 120)">>, <<"src/main.bp">>, 8, 21, <<"write `Async<Result<T, E>>` (or `Async<T>` when it cannot fail)">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_type_removed_future">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_future">>, <<"cases/effect_type_removed_future">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"`@Future` was removed \x{E2}\x{80}\x{94} the wrapper is `Async<T>`, which never fails (decision 120)">>, <<"src/main.bp">>, 8, 21, <<"write `Async<Result<T, E>>` (or `Async<T>` when it cannot fail)">>, []}]}))), Refusals@3)])
    end).

'__bp_init_13'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_13'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_13'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_13'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_14'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_future_generator">>, <<"cases/effect_type_removed_future_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"`@FutureGenerator` was removed \x{E2}\x{80}\x{94} the asynchronous sequence is `AsyncIter` (decision 122)">>, <<"src/main.bp">>, 6, 21, <<"write `AsyncIter<Result<T, E>>` (or `AsyncIter<T>`)">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_type_removed_future_generator">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_future_generator">>, <<"cases/effect_type_removed_future_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"`@FutureGenerator` was removed \x{E2}\x{80}\x{94} the asynchronous sequence is `AsyncIter` (decision 122)">>, <<"src/main.bp">>, 6, 21, <<"write `AsyncIter<Result<T, E>>` (or `AsyncIter<T>`)">>, []}]}))), Refusals@3)])
    end).

'__bp_init_14'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_14'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_14'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_14'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_15'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_future_no_error">>, <<"cases/effect_type_removed_future_no_error">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"`@Future` was removed \x{E2}\x{80}\x{94} the wrapper is `Async<T>`, which never fails (decision 120)">>, <<"src/main.bp">>, 11, 12, <<"write `Async<Result<T, E>>` (or `Async<T>` when it cannot fail)">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_type_removed_future_no_error">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_future_no_error">>, <<"cases/effect_type_removed_future_no_error">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"`@Future` was removed \x{E2}\x{80}\x{94} the wrapper is `Async<T>`, which never fails (decision 120)">>, <<"src/main.bp">>, 11, 12, <<"write `Async<Result<T, E>>` (or `Async<T>` when it cannot fail)">>, []}]}))), Refusals@3)])
    end).

'__bp_init_15'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_15'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_15'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_15'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_16'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_generator">>, <<"cases/effect_type_removed_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"`@Generator` was renamed `Iter` (decision 122)">>, <<"src/main.bp">>, 8, 20, <<"write `Iter<T>`">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_type_removed_generator">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_generator">>, <<"cases/effect_type_removed_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"`@Generator` was renamed `Iter` (decision 122)">>, <<"src/main.bp">>, 8, 20, <<"write `Iter<T>`">>, []}]}))), Refusals@3)])
    end).

'__bp_init_16'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_16'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_16'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_16'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_17'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_iterable">>, <<"cases/effect_type_removed_iterable">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"this sequence type left the language (decisions 103, 122)">>, <<"src/main.bp">>, 11, 14, <<"write `AsyncIter<T>`, `Iter<T>` or `YieldStep<T>`">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_type_removed_iterable">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_iterable">>, <<"cases/effect_type_removed_iterable">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"this sequence type left the language (decisions 103, 122)">>, <<"src/main.bp">>, 11, 14, <<"write `AsyncIter<T>`, `Iter<T>` or `YieldStep<T>`">>, []}]}))), Refusals@3)])
    end).

'__bp_init_17'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_17'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_17'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_17'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_18'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_iterator_step">>, <<"cases/effect_type_removed_iterator_step">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"this sequence type left the language (decisions 103, 122)">>, <<"src/main.bp">>, 10, 16, <<"write `AsyncIter<T>`, `Iter<T>` or `YieldStep<T>`">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_type_removed_iterator_step">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_iterator_step">>, <<"cases/effect_type_removed_iterator_step">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"this sequence type left the language (decisions 103, 122)">>, <<"src/main.bp">>, 10, 16, <<"write `AsyncIter<T>`, `Iter<T>` or `YieldStep<T>`">>, []}]}))), Refusals@3)])
    end).

'__bp_init_18'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_18'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_18'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_18'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_19'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_result_generator">>, <<"cases/effect_type_removed_result_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"`@ResultGenerator` was removed \x{E2}\x{80}\x{94} the item carries the failure (decision 122)">>, <<"src/main.bp">>, 6, 20, <<"write `Iter<Result<T, E>>`">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_type_removed_result_generator">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_result_generator">>, <<"cases/effect_type_removed_result_generator">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"`@ResultGenerator` was removed \x{E2}\x{80}\x{94} the item carries the failure (decision 122)">>, <<"src/main.bp">>, 6, 20, <<"write `Iter<Result<T, E>>`">>, []}]}))), Refusals@3)])
    end).

'__bp_init_19'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_19'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_19'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_19'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_20'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_use">>, <<"cases/effect_type_removed_use">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"`@Use` was removed \x{E2}\x{80}\x{94} one wrapper, `Component<R>` (decisions 128, 354)">>, <<"src/main.bp">>, 8, 27, <<"write `Component<R>`">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_type_removed_use">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_use">>, <<"cases/effect_type_removed_use">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"`@Use` was removed \x{E2}\x{80}\x{94} one wrapper, `Component<R>` (decisions 128, 354)">>, <<"src/main.bp">>, 8, 27, <<"write `Component<R>`">>, []}]}))), Refusals@3)])
    end).

'__bp_init_20'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_20'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_20'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_20'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_21'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_yield">>, <<"cases/effect_type_removed_yield">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"this sequence type left the language (decisions 103, 122)">>, <<"src/main.bp">>, 9, 16, <<"write `AsyncIter<T>`, `Iter<T>` or `YieldStep<T>`">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"effect_type_removed_yield">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"effect_type_removed_yield">>, <<"cases/effect_type_removed_yield">>, <<"">>), [{std@compiler@@Diagnostic, <<"effect-type-removed">>, <<"this sequence type left the language (decisions 103, 122)">>, <<"src/main.bp">>, 9, 16, <<"write `AsyncIter<T>`, `Iter<T>` or `YieldStep<T>`">>, []}]}))), Refusals@3)])
    end).

'__bp_init_21'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_21'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_21'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_21'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_22'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"iterator_error_param_removed">>, <<"cases/iterator_error_param_removed">>, <<"">>), [{std@compiler@@Diagnostic, <<"iterator-error-param-removed">>, <<"`Iter` has no error parameter \x{E2}\x{80}\x{94} the item carries the failure (decision 122)">>, <<"src/main.bp">>, 10, 34, <<"write `Iter<Result<T, E>>`">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"iterator_error_param_removed">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"iterator_error_param_removed">>, <<"cases/iterator_error_param_removed">>, <<"">>), [{std@compiler@@Diagnostic, <<"iterator-error-param-removed">>, <<"`Iter` has no error parameter \x{E2}\x{80}\x{94} the item carries the failure (decision 122)">>, <<"src/main.bp">>, 10, 34, <<"write `Iter<Result<T, E>>`">>, []}]}))), Refusals@3)])
    end).

'__bp_init_22'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_22'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_22'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_22'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_23'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"loop_await_removed">>, <<"cases/loop_await_removed">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"this token cannot appear here">>, <<"src/main.bp">>, 15, 10, <<"unexpected `await`">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"loop_await_removed">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"loop_await_removed">>, <<"cases/loop_await_removed">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"this token cannot appear here">>, <<"src/main.bp">>, 15, 10, <<"unexpected `await`">>, []}]}))), Refusals@3)])
    end).

'__bp_init_23'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_23'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_23'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_23'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_24'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"loop_condition_parenthesised">>, <<"cases/loop_condition_parenthesised">>, <<"">>), [{std@compiler@@Diagnostic, <<"removed-loop-parenthesised">>, <<"`loop (\x{E2}\x{80}\x{A6})` does not exist \x{E2}\x{80}\x{94} `for` iterates, `while` repeats">>, <<"src/main.bp">>, 10, 5, <<"write `for (xs) { x -> \x{E2}\x{80}\x{A6} }` or `while (cond) { \x{E2}\x{80}\x{A6} }`">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"loop_condition_parenthesised">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"loop_condition_parenthesised">>, <<"cases/loop_condition_parenthesised">>, <<"">>), [{std@compiler@@Diagnostic, <<"removed-loop-parenthesised">>, <<"`loop (\x{E2}\x{80}\x{A6})` does not exist \x{E2}\x{80}\x{94} `for` iterates, `while` repeats">>, <<"src/main.bp">>, 10, 5, <<"write `for (xs) { x -> \x{E2}\x{80}\x{A6} }` or `while (cond) { \x{E2}\x{80}\x{A6} }`">>, []}]}))), Refusals@3)])
    end).

'__bp_init_24'() ->
    case persistent_term:get({effect_annotation_removed_refused_127@main, '__bp_init_24'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_24'(), persistent_term:put({effect_annotation_removed_refused_127@main, '__bp_init_24'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

%% @Async — eager lowering
main() ->
    conformance_lib@candidate:finish(accepted(), answers(), conformance_lib@adapter:target()).

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__S, __A, __E) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, unicode:characters_to_binary(lists:sublist(__L, __B + 1, erlang:max(__F - __B, 0))) end)(Self, Start, End);
        false ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, Start)
    end.

'__bp_ets'(Name, Seed) ->
    case erlang:whereis(Name) of
        undefined -> '__bp_ets_wait'(Name, Seed, undefined);
        _ -> Name
    end.

'__bp_ets_wait'(Name, Seed, Cand) ->
    case erlang:whereis(Name) of
        undefined ->
            Next = case (erlang:is_pid(Cand) andalso erlang:is_process_alive(Cand)) of
                true -> Cand;
                false -> case std@beam:etsWhereis(Name) of
                    undefined -> erlang:spawn(effect_annotation_removed_refused_127@main, '__bp_ets_owner', [Name, Seed]);
                    _ -> Cand
                end
            end,
            erlang:yield(),
            '__bp_ets_wait'(Name, Seed, Next);
        _ -> Name
    end.

'__bp_ets_owner'(Name, Seed) ->
    case try
        std@beam:etsNew(Name, [named_table, public, set])
    catch
        error:badarg ->
            '__bp_lost'
    end of
        '__bp_lost' -> ok;
        _ ->
            std@beam:etsPut(Name, {Name, Seed}),
            erlang:register(Name, erlang:self()),
            timer:sleep(infinity)
    end.

'__bp_field'(V, F) when erlang:is_map(V) -> maps:get(F, V);
'__bp_field'(V, F) -> erlang:apply(erlang:element(1, V), '__bp_get', [V, F]).

'_botopink_init'() ->
    '__bp_init_0'(),
    '__bp_init_1'(),
    '__bp_init_2'(),
    '__bp_init_3'(),
    '__bp_init_4'(),
    '__bp_init_5'(),
    '__bp_init_6'(),
    '__bp_init_7'(),
    '__bp_init_8'(),
    '__bp_init_9'(),
    '__bp_init_10'(),
    '__bp_init_11'(),
    '__bp_init_12'(),
    '__bp_init_13'(),
    '__bp_init_14'(),
    '__bp_init_15'(),
    '__bp_init_16'(),
    '__bp_init_17'(),
    '__bp_init_18'(),
    '__bp_init_19'(),
    '__bp_init_20'(),
    '__bp_init_21'(),
    '__bp_init_22'(),
    '__bp_init_23'(),
    '__bp_init_24'(),
    ok.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '__bp_load_siblings'(),
    '_botopink_init'(),
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

'__bp_priv__answers'() -> answers().

'__bp_priv____bp_tab_answers'() -> '__bp_tab_answers'().

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).

'__bp_priv____bp_ets'(A0, A1) -> '__bp_ets'(A0, A1).
