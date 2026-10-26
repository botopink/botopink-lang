-module(no_declaration_files_compiler_value_575@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, '__bp_ets_owner'/2, '__bp_loaded'/2, '__bp_load_module'/3, '__bp_run'/1, '__bp_run_async'/1, '__bp_run_none'/0, '__bp_run_async_none'/0, '__bp_executor_0'/0, '__bp_executor_1'/0, '__bp_executor_2'/0, '__bp_executor_3'/0, '__bp_executor_4'/0, '__bp_executor_5'/0, '__bp_executor_6'/0, '__bp_executor_7'/0, '__bp_executor_8'/0, '__bp_executor_9'/0, '__bp_executor_10'/0, '__bp_executor_11'/0, '__bp_executor_12'/0, '__bp_executor_13'/0, '__bp_executor_14'/0, '__bp_executor_15'/0, '__bp_executor_16'/0, '__bp_executor_17'/0, main/0, accepted/0, '__bp_comptime_0_at'/0, '__bp_init_0'/0, '__bp_init_1'/0, '__bp_init_2'/0, '__bp_init_3'/0, '__bp_init_4'/0, '__bp_init_5'/0, '__bp_init_6'/0, '__bp_init_7'/0, '__bp_init_8'/0, '__bp_init_9'/0, '__bp_init_10'/0, '__bp_init_11'/0, '__bp_init_12'/0, '__bp_init_13'/0, '__bp_init_14'/0, '__bp_init_15'/0, '__bp_init_16'/0, '__bp_init_17'/0, '__bp_priv__answers'/0, '__bp_priv____bp_tab_answers'/0, '__bp_priv__string_slice'/3, '__bp_priv____bp_ets'/2]).

%% import RunFailureKind

%% type Asset: path, bytes, size, hash

%% behavior string

%% import __bp_run__bp_load__cases__compiler_decorator_three_kinds

%% import __bp_run__bp_load__cases__decorator_member_captures

%% import __bp_run__bp_load__cases__external_library_source_annotation

%% import __bp_run__bp_load__cases__external_library_source_beside_emit

%% import __bp_run__bp_load__cases__external_library_source_beside_emit_split

%% import __bp_run__bp_load__cases__external_library_source_beside_member

%% import __bp_run__bp_load__cases__init_executor_before_main

%% import __bp_run__bp_load__cases__type_param_generic_form

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

%% import __bp_ns_adapter__buildOutput, __bp_ns_adapter__frames, __bp_ns_adapter__ranOf, __bp_ns_adapter__target, __bp_ns_candidate__finish, __bp_ns_observe__ranAnswer, __bp_ns_observe__refusalOf, __bp_ns_observe__refusedAnswer

%% The snapshot, read as a build input (decision 989 (5)).

accepted() ->
    <<"botopink-cell 2\n">>.

%% What each case answered, in the order the cases ran.

%% var answers — beamMemory(.Ets)
answers() ->
    std@beam:etsGet('__bp_tab_answers'(), no_declaration_files_compiler_value_575@main@@answers, 2).

'__bp_tab_answers'() ->
    case erlang:whereis(no_declaration_files_compiler_value_575@main@@answers) of
        undefined -> '__bp_ets'(no_declaration_files_compiler_value_575@main@@answers, []);
        _ -> no_declaration_files_compiler_value_575@main@@answers
    end.

%% One case, expanded where it is called (decision 808 (2)): a refused load answers its

%% diagnostics, a loaded one runs and answers its output.

'__bp_comptime_0_at'() ->
    0.

'__bp_executor_0'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_compiler_decorator_three_kinds@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"compiler_decorator_three_kinds">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"compiler_decorator_three_kinds">>, <<"cases/compiler_decorator_three_kinds">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_0'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_0'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_0'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_0'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_1'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_decorator_member_captures@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"decorator_member_captures">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"decorator_member_captures">>, <<"cases/decorator_member_captures">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_1'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_1'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_1'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_1'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_2'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_external_library_source_annotation@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"external_library_source_annotation">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"external_library_source_annotation">>, <<"cases/external_library_source_annotation">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_2'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_2'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_2'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_2'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_3'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_external_library_source_beside_emit@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"external_library_source_beside_emit">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"external_library_source_beside_emit">>, <<"cases/external_library_source_beside_emit">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_3'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_3'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_3'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_3'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_4'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_external_library_source_beside_emit_split@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"external_library_source_beside_emit_split">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"external_library_source_beside_emit_split">>, <<"cases/external_library_source_beside_emit_split">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_4'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_4'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_4'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_4'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_5'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_external_library_source_beside_member@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"external_library_source_beside_member">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"external_library_source_beside_member">>, <<"cases/external_library_source_beside_member">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_5'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_5'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_5'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_5'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_6'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"builtin_module_not_lowered">>, <<"cases/builtin_module_not_lowered">>, <<"">>), [{std@compiler@@Diagnostic, <<"builtin-not-lowered">>, <<"builtin-not-lowered: `@module()` is declared but no target lowers it">>, <<"src/main.bp">>, 8, 13, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"builtin_module_not_lowered">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"builtin_module_not_lowered">>, <<"cases/builtin_module_not_lowered">>, <<"">>), [{std@compiler@@Diagnostic, <<"builtin-not-lowered">>, <<"builtin-not-lowered: `@module()` is declared but no target lowers it">>, <<"src/main.bp">>, 8, 13, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_6'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_6'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_6'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_6'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_7'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"compiler_output_outside_decorator">>, <<"cases/compiler_output_outside_decorator">>, <<"">>), [{std@compiler@@Diagnostic, <<"compiler-output-outside-decorator">>, <<"compiler-output-outside-decorator: `compiler.setMeta` writes to the annotated declaration, and only a decorator has one">>, <<"src/main.bp">>, 11, 14, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"compiler_output_outside_decorator">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"compiler_output_outside_decorator">>, <<"cases/compiler_output_outside_decorator">>, <<"">>), [{std@compiler@@Diagnostic, <<"compiler-output-outside-decorator">>, <<"compiler-output-outside-decorator: `compiler.setMeta` writes to the annotated declaration, and only a decorator has one">>, <<"src/main.bp">>, 11, 14, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_7'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_7'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_7'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_7'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_8'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"declare_in_behavior">>, <<"cases/declare_in_behavior">>, <<"">>), [{std@compiler@@Diagnostic, <<"declare-in-behavior">>, <<"declare-in-behavior: `Greeter.greet` is a `declare fn` inside a behavior \x{E2}\x{80}\x{94} a behavior declares a member's signature, or a `default fn` with a body">>, <<"src/main.bp">>, 7, 16, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"declare_in_behavior">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"declare_in_behavior">>, <<"cases/declare_in_behavior">>, <<"">>), [{std@compiler@@Diagnostic, <<"declare-in-behavior">>, <<"declare-in-behavior: `Greeter.greet` is a `declare fn` inside a behavior \x{E2}\x{80}\x{94} a behavior declares a member's signature, or a `default fn` with a body">>, <<"src/main.bp">>, 7, 16, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_8'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_8'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_8'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_8'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_9'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"declare_without_implementation">>, <<"cases/declare_without_implementation">>, <<"">>), [{std@compiler@@Diagnostic, <<"declare-without-implementation">>, <<"declare-without-implementation: `now` is a bodyless `declare fn`, and no annotation implements it">>, <<"src/main.bp">>, 6, 12, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"declare_without_implementation">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"declare_without_implementation">>, <<"cases/declare_without_implementation">>, <<"">>), [{std@compiler@@Diagnostic, <<"declare-without-implementation">>, <<"declare-without-implementation: `now` is a bodyless `declare fn`, and no annotation implements it">>, <<"src/main.bp">>, 6, 12, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_9'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_9'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_9'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_9'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_10'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"declare_without_implementation_method">>, <<"cases/declare_without_implementation_method">>, <<"">>), [{std@compiler@@Diagnostic, <<"declare-without-implementation">>, <<"declare-without-implementation: `Repo.find` is a bodyless `declare fn`, and no annotation implements it">>, <<"src/main.bp">>, 7, 20, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"declare_without_implementation_method">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"declare_without_implementation_method">>, <<"cases/declare_without_implementation_method">>, <<"">>), [{std@compiler@@Diagnostic, <<"declare-without-implementation">>, <<"declare-without-implementation: `Repo.find` is a bodyless `declare fn`, and no annotation implements it">>, <<"src/main.bp">>, 7, 20, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_10'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_10'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_10'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_10'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_11'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"declare_without_implementation_static">>, <<"cases/declare_without_implementation_static">>, <<"">>), [{std@compiler@@Diagnostic, <<"declare-without-implementation">>, <<"declare-without-implementation: `Clock.ticks` is a bodyless `declare fn`, and no annotation implements it">>, <<"src/main.bp">>, 7, 20, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"declare_without_implementation_static">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"declare_without_implementation_static">>, <<"cases/declare_without_implementation_static">>, <<"">>), [{std@compiler@@Diagnostic, <<"declare-without-implementation">>, <<"declare-without-implementation: `Clock.ticks` is a bodyless `declare fn`, and no annotation implements it">>, <<"src/main.bp">>, 7, 20, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_11'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_11'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_11'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_11'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_12'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"implementation_twice">>, <<"cases/implementation_twice">>, <<"">>), [{std@compiler@@Diagnostic, <<"implementation-twice">>, <<"implementation-twice: `magnitude` is implemented twice for `.JavaScript` \x{E2}\x{80}\x{94} one implementation per target">>, <<"src/main.bp">>, 7, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"implementation_twice">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"implementation_twice">>, <<"cases/implementation_twice">>, <<"">>), [{std@compiler@@Diagnostic, <<"implementation-twice">>, <<"implementation-twice: `magnitude` is implemented twice for `.JavaScript` \x{E2}\x{80}\x{94} one implementation per target">>, <<"src/main.bp">>, 7, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_12'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_12'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_12'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_12'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_13'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"removed_type_bare_param">>, <<"cases/removed_type_bare_param">>, <<"">>), [{std@compiler@@Diagnostic, <<"removed-type-bare-param">>, <<"the type of a type is written `type<T>`">>, <<"src/main.bp">>, 6, 29, <<"write `type<T>`">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"removed_type_bare_param">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"removed_type_bare_param">>, <<"cases/removed_type_bare_param">>, <<"">>), [{std@compiler@@Diagnostic, <<"removed-type-bare-param">>, <<"the type of a type is written `type<T>`">>, <<"src/main.bp">>, 6, 29, <<"write `type<T>`">>, []}]}))), Refusals@3)])
    end).

'__bp_init_13'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_13'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_13'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_13'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_14'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"type_param_binds_mismatch">>, <<"cases/type_param_binds_mismatch">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"type mismatch: `#[provides]`'s `t` binds `T`, which is `i32` here, to `string`">>, <<"src/main.bp">>, 13, 12, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"type_param_binds_mismatch">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"type_param_binds_mismatch">>, <<"cases/type_param_binds_mismatch">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"type mismatch: `#[provides]`'s `t` binds `T`, which is `i32` here, to `string`">>, <<"src/main.bp">>, 13, 12, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_14'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_14'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_14'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_14'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_15'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_of_value">>, <<"cases/typeinfo_of_value">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-unknown-declaration">>, <<"typeinfo-unknown-declaration: `@typeInfo` reflects a declaration this module declares or imports, and this names none">>, <<"src/main.bp">>, 10, 38, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"typeinfo_of_value">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_of_value">>, <<"cases/typeinfo_of_value">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-unknown-declaration">>, <<"typeinfo-unknown-declaration: `@typeInfo` reflects a declaration this module declares or imports, and this names none">>, <<"src/main.bp">>, 10, 38, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_15'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_15'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_15'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_15'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_16'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_init_executor_before_main@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"init_executor_before_main">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"init_executor_before_main">>, <<"cases/init_executor_before_main">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_16'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_16'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_16'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_16'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_17'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_type_param_generic_form@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"type_param_generic_form">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"type_param_generic_form">>, <<"cases/type_param_generic_form">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_17'() ->
    case persistent_term:get({no_declaration_files_compiler_value_575@main, '__bp_init_17'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_17'(), persistent_term:put({no_declaration_files_compiler_value_575@main, '__bp_init_17'}, __BpV), __BpV;
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
                    undefined -> erlang:spawn(no_declaration_files_compiler_value_575@main, '__bp_ets_owner', [Name, Seed]);
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
