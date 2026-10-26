-module(decorator_meta_keyed_by_type_298@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, '__bp_ets_owner'/2, '__bp_loaded'/2, '__bp_load_module'/3, '__bp_run'/1, '__bp_run_async'/1, '__bp_run_none'/0, '__bp_run_async_none'/0, '__bp_executor_0'/0, '__bp_executor_1'/0, '__bp_executor_2'/0, '__bp_executor_3'/0, '__bp_executor_4'/0, '__bp_executor_5'/0, '__bp_executor_6'/0, '__bp_executor_7'/0, '__bp_executor_8'/0, '__bp_executor_9'/0, main/0, accepted/0, '__bp_comptime_0_at'/0, '__bp_init_0'/0, '__bp_init_1'/0, '__bp_init_2'/0, '__bp_init_3'/0, '__bp_init_4'/0, '__bp_init_5'/0, '__bp_init_6'/0, '__bp_init_7'/0, '__bp_init_8'/0, '__bp_init_9'/0, '__bp_priv__answers'/0, '__bp_priv____bp_tab_answers'/0, '__bp_priv__string_slice'/3, '__bp_priv____bp_ets'/2]).

%% import RunFailureKind

%% type Asset: path, bytes, size, hash

%% behavior string

%% import __bp_run__bp_load__cases__meta_typed

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

%% import __bp_ns_adapter__buildOutput, __bp_ns_adapter__frames, __bp_ns_adapter__ranOf, __bp_ns_adapter__target, __bp_ns_candidate__finish, __bp_ns_observe__refusalOf, __bp_ns_observe__refusedAnswer, __bp_ns_observe__ranAnswer

%% The snapshot, read as a build input (decision 989 (5)).

accepted() ->
    <<"botopink-cell 2\n">>.

%% What each case answered, in the order the cases ran.

%% var answers — beamMemory(.Ets)
answers() ->
    std@beam:etsGet('__bp_tab_answers'(), decorator_meta_keyed_by_type_298@main@@answers, 2).

'__bp_tab_answers'() ->
    case erlang:whereis(decorator_meta_keyed_by_type_298@main@@answers) of
        undefined -> '__bp_ets'(decorator_meta_keyed_by_type_298@main@@answers, []);
        _ -> decorator_meta_keyed_by_type_298@main@@answers
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
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_add_outside_decorator">>, <<"cases/meta_add_outside_decorator">>, <<"">>), [{std@compiler@@Diagnostic, <<"compiler-output-outside-decorator">>, <<"compiler-output-outside-decorator: `compiler.addMeta` writes to the annotated declaration, and only a decorator has one">>, <<"src/main.bp">>, 10, 14, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"meta_add_outside_decorator">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_add_outside_decorator">>, <<"cases/meta_add_outside_decorator">>, <<"">>), [{std@compiler@@Diagnostic, <<"compiler-output-outside-decorator">>, <<"compiler-output-outside-decorator: `compiler.addMeta` writes to the annotated declaration, and only a decorator has one">>, <<"src/main.bp">>, 10, 14, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_0'() ->
    case persistent_term:get({decorator_meta_keyed_by_type_298@main, '__bp_init_0'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_0'(), persistent_term:put({decorator_meta_keyed_by_type_298@main, '__bp_init_0'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_1'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_catalogue_generic">>, <<"cases/meta_catalogue_generic">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-meta-type">>, <<"typeinfo-meta-type: `metaAll(Check)` on a catalogue entry names a generic record, whose type arguments this read cannot spell">>, <<"src/main.bp">>, 28, 25, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"meta_catalogue_generic">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_catalogue_generic">>, <<"cases/meta_catalogue_generic">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-meta-type">>, <<"typeinfo-meta-type: `metaAll(Check)` on a catalogue entry names a generic record, whose type arguments this read cannot spell">>, <<"src/main.bp">>, 28, 25, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_1'() ->
    case persistent_term:get({decorator_meta_keyed_by_type_298@main, '__bp_init_1'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_1'(), persistent_term:put({decorator_meta_keyed_by_type_298@main, '__bp_init_1'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_2'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_field_type">>, <<"cases/meta_field_type">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-meta-field-type">>, <<"decorator-meta-field-type: the field `run: fn() -> i32` of the meta record `Hook` holds no data the compiler rebuilds where the meta is read">>, <<"src/main.bp">>, 15, 22, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"meta_field_type">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_field_type">>, <<"cases/meta_field_type">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-meta-field-type">>, <<"decorator-meta-field-type: the field `run: fn() -> i32` of the meta record `Hook` holds no data the compiler rebuilds where the meta is read">>, <<"src/main.bp">>, 15, 22, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_2'() ->
    case persistent_term:get({decorator_meta_keyed_by_type_298@main, '__bp_init_2'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_2'(), persistent_term:put({decorator_meta_keyed_by_type_298@main, '__bp_init_2'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_3'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_not_record">>, <<"cases/meta_not_record">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-meta-not-record">>, <<"decorator-meta-not-record: `decl.setMeta(\x{E2}\x{80}\x{A6})` records a value of a record type, written as its constructor at the call">>, <<"src/main.bp">>, 14, 22, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"meta_not_record">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_not_record">>, <<"cases/meta_not_record">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-meta-not-record">>, <<"decorator-meta-not-record: `decl.setMeta(\x{E2}\x{80}\x{A6})` records a value of a record type, written as its constructor at the call">>, <<"src/main.bp">>, 14, 22, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_3'() ->
    case persistent_term:get({decorator_meta_keyed_by_type_298@main, '__bp_init_3'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_3'(), persistent_term:put({decorator_meta_keyed_by_type_298@main, '__bp_init_3'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_4'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_read_at_build">>, <<"cases/meta_read_at_build">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-meta-at-build">>, <<"typeinfo-meta-at-build: `meta(T)` on a catalogue entry reads run-time data, and this body runs while the program compiles">>, <<"src/main.bp">>, 15, 24, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"meta_read_at_build">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_read_at_build">>, <<"cases/meta_read_at_build">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-meta-at-build">>, <<"typeinfo-meta-at-build: `meta(T)` on a catalogue entry reads run-time data, and this body runs while the program compiles">>, <<"src/main.bp">>, 15, 24, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_4'() ->
    case persistent_term:get({decorator_meta_keyed_by_type_298@main, '__bp_init_4'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_4'(), persistent_term:put({decorator_meta_keyed_by_type_298@main, '__bp_init_4'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_5'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_read_not_type">>, <<"cases/meta_read_not_type">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-meta-type">>, <<"typeinfo-meta-type: `metaAll(T)` takes one record type of this module or its imports \x{E2}\x{80}\x{94} `metaAll(Entity)`, `metaAll(orm.Entity)`">>, <<"src/main.bp">>, 21, 52, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"meta_read_not_type">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_read_not_type">>, <<"cases/meta_read_not_type">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-meta-type">>, <<"typeinfo-meta-type: `metaAll(T)` takes one record type of this module or its imports \x{E2}\x{80}\x{94} `metaAll(Entity)`, `metaAll(orm.Entity)`">>, <<"src/main.bp">>, 21, 52, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_5'() ->
    case persistent_term:get({decorator_meta_keyed_by_type_298@main, '__bp_init_5'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_5'(), persistent_term:put({decorator_meta_keyed_by_type_298@main, '__bp_init_5'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_6'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_several">>, <<"cases/meta_several">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-meta-several">>, <<"typeinfo-meta-several: `City` holds 2 `Index` values, and `meta(Index)` answers one">>, <<"src/main.bp">>, 18, 44, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"meta_several">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_several">>, <<"cases/meta_several">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-meta-several">>, <<"typeinfo-meta-several: `City` holds 2 `Index` values, and `meta(Index)` answers one">>, <<"src/main.bp">>, 18, 44, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_6'() ->
    case persistent_term:get({decorator_meta_keyed_by_type_298@main, '__bp_init_6'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_6'(), persistent_term:put({decorator_meta_keyed_by_type_298@main, '__bp_init_6'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_7'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_twice">>, <<"cases/meta_twice">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-meta-twice">>, <<"decorator-meta-twice: `#[entity]` records a second `Entity` on `City`, which holds one">>, <<"src/main.bp">>, 14, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"meta_twice">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_twice">>, <<"cases/meta_twice">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-meta-twice">>, <<"decorator-meta-twice: `#[entity]` records a second `Entity` on `City`, which holds one">>, <<"src/main.bp">>, 14, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_7'() ->
    case persistent_term:get({decorator_meta_keyed_by_type_298@main, '__bp_init_7'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_7'(), persistent_term:put({decorator_meta_keyed_by_type_298@main, '__bp_init_7'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_8'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_catalogue_private_type">>, <<"cases/meta_catalogue_private_type">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-all-private">>, <<"typeinfo-all-private: `City` of `models` carries the meta type `Entity` of `models`, which is not `pub`, so the catalogue cannot carry it">>, <<"src/main.bp">>, 11, 11, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"meta_catalogue_private_type">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"meta_catalogue_private_type">>, <<"cases/meta_catalogue_private_type">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-all-private">>, <<"typeinfo-all-private: `City` of `models` carries the meta type `Entity` of `models`, which is not `pub`, so the catalogue cannot carry it">>, <<"src/main.bp">>, 11, 11, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_8'() ->
    case persistent_term:get({decorator_meta_keyed_by_type_298@main, '__bp_init_8'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_8'(), persistent_term:put({decorator_meta_keyed_by_type_298@main, '__bp_init_8'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_9'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_meta_typed@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"meta_typed">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"meta_typed">>, <<"cases/meta_typed">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_9'() ->
    case persistent_term:get({decorator_meta_keyed_by_type_298@main, '__bp_init_9'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_9'(), persistent_term:put({decorator_meta_keyed_by_type_298@main, '__bp_init_9'}, __BpV), __BpV;
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
                    undefined -> erlang:spawn(decorator_meta_keyed_by_type_298@main, '__bp_ets_owner', [Name, Seed]);
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
