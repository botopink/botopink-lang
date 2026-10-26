-module(decorator_four_output_places_216@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, '__bp_ets_owner'/2, '__bp_loaded'/2, '__bp_load_module'/3, '__bp_run'/1, '__bp_run_async'/1, '__bp_run_none'/0, '__bp_run_async_none'/0, '__bp_executor_0'/0, '__bp_executor_1'/0, '__bp_executor_2'/0, '__bp_executor_3'/0, '__bp_executor_4'/0, '__bp_executor_5'/0, '__bp_executor_6'/0, '__bp_executor_7'/0, '__bp_executor_8'/0, '__bp_executor_9'/0, '__bp_executor_10'/0, '__bp_executor_11'/0, '__bp_executor_12'/0, '__bp_executor_13'/0, main/0, accepted/0, '__bp_comptime_0_at'/0, '__bp_init_0'/0, '__bp_init_1'/0, '__bp_init_2'/0, '__bp_init_3'/0, '__bp_init_4'/0, '__bp_init_5'/0, '__bp_init_6'/0, '__bp_init_7'/0, '__bp_init_8'/0, '__bp_init_9'/0, '__bp_init_10'/0, '__bp_init_11'/0, '__bp_init_12'/0, '__bp_init_13'/0, '__bp_priv__answers'/0, '__bp_priv____bp_tab_answers'/0, '__bp_priv__string_slice'/3, '__bp_priv____bp_ets'/2]).

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

%% import __bp_ns_adapter__buildOutput, __bp_ns_adapter__target, __bp_ns_adapter__frames, __bp_ns_adapter__ranOf, __bp_ns_candidate__finish, __bp_ns_observe__refusedAnswer, __bp_ns_observe__refusalOf, __bp_ns_observe__ranAnswer

%% The snapshot, read as a build input (decision 989 (5)).

accepted() ->
    <<"botopink-cell 2\n">>.

%% What each case answered, in the order the cases ran.

%% var answers — beamMemory(.Ets)
answers() ->
    std@beam:etsGet('__bp_tab_answers'(), decorator_four_output_places_216@main@@answers, 2).

'__bp_tab_answers'() ->
    case erlang:whereis(decorator_four_output_places_216@main@@answers) of
        undefined -> '__bp_ets'(decorator_four_output_places_216@main@@answers, []);
        _ -> decorator_four_output_places_216@main@@answers
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
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_member_duplicate">>, <<"cases/decorator_add_member_duplicate">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-member-duplicate">>, <<"decorator-member-duplicate: `#[sized]` adds `size` to `Box`, which already has a member called `size`">>, <<"src/main.bp">>, 12, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_add_member_duplicate">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_member_duplicate">>, <<"cases/decorator_add_member_duplicate">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-member-duplicate">>, <<"decorator-member-duplicate: `#[sized]` adds `size` to `Box`, which already has a member called `size`">>, <<"src/main.bp">>, 12, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_0'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_0'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_0'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_0'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_1'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_member_not_one">>, <<"cases/decorator_add_member_not_one">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-member-not-one-fn">>, <<"decorator-member-not-one-fn: `#[twice]` added a member to `Pair` that is not one `fn`: `pub fn a() -> i32 { return 1; } pub fn b() -> i32 { return 2; }`">>, <<"src/main.bp">>, 11, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_add_member_not_one">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_member_not_one">>, <<"cases/decorator_add_member_not_one">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-member-not-one-fn">>, <<"decorator-member-not-one-fn: `#[twice]` added a member to `Pair` that is not one `fn`: `pub fn a() -> i32 { return 1; } pub fn b() -> i32 { return 2; }`">>, <<"src/main.bp">>, 11, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_1'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_1'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_1'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_1'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_2'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_member_on_fn">>, <<"cases/decorator_add_member_on_fn">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-member-without-type">>, <<"decorator-member-without-type: `#[helper]` on the function `work` calls `decl.addMember`, and a member belongs to a type">>, <<"src/main.bp">>, 13, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_add_member_on_fn">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_member_on_fn">>, <<"cases/decorator_add_member_on_fn">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-member-without-type">>, <<"decorator-member-without-type: `#[helper]` on the function `work` calls `decl.addMember`, and a member belongs to a type">>, <<"src/main.bp">>, 13, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_2'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_2'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_2'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_2'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_3'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_type_duplicate">>, <<"cases/decorator_add_type_duplicate">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-type-duplicate">>, <<"decorator-type-duplicate: `#[table]` declares `City.Columns`, and `City` already has an associated type `Columns`">>, <<"src/main.bp">>, 16, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_add_type_duplicate">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_type_duplicate">>, <<"cases/decorator_add_type_duplicate">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-type-duplicate">>, <<"decorator-type-duplicate: `#[table]` declares `City.Columns`, and `City` already has an associated type `Columns`">>, <<"src/main.bp">>, 16, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_3'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_3'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_3'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_3'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_4'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_type_name">>, <<"cases/decorator_add_type_name">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-type-name">>, <<"decorator-type-name: `#[entity]` names an associated type of `City` `columns`, which is not a type name">>, <<"src/main.bp">>, 11, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_add_type_name">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_type_name">>, <<"cases/decorator_add_type_name">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-type-name">>, <<"decorator-type-name: `#[entity]` names an associated type of `City` `columns`, which is not a type name">>, <<"src/main.bp">>, 11, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_4'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_4'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_4'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_4'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_5'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_type_not_one">>, <<"cases/decorator_add_type_not_one">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-type-not-one-type">>, <<"decorator-type-not-one-type: `#[entity]` declares `City.Columns` from a source that is not one type: `(id: string) fn extra() -> void {}`">>, <<"src/main.bp">>, 11, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_add_type_not_one">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_type_not_one">>, <<"cases/decorator_add_type_not_one">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-type-not-one-type">>, <<"decorator-type-not-one-type: `#[entity]` declares `City.Columns` from a source that is not one type: `(id: string) fn extra() -> void {}`">>, <<"src/main.bp">>, 11, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_5'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_5'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_5'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_5'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_6'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_type_without_owner">>, <<"cases/decorator_add_type_without_owner">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-type-without-owner">>, <<"decorator-type-without-owner: `#[helper]` on the function `work` calls `decl.addType`, and an associated type belongs to a type">>, <<"src/main.bp">>, 10, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_add_type_without_owner">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_add_type_without_owner">>, <<"cases/decorator_add_type_without_owner">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-type-without-owner">>, <<"decorator-type-without-owner: `#[helper]` on the function `work` calls `decl.addType`, and an associated type belongs to a type">>, <<"src/main.bp">>, 10, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_6'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_6'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_6'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_6'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_7'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_member_unknown">>, <<"cases/decorator_member_unknown">>, <<"">>), [{std@compiler@@Diagnostic, <<"unknown-associated-fn">>, <<"unknown-associated-fn: `City` has no associated fn `revisions`">>, <<"src/main.bp">>, 23, 16, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_member_unknown">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_member_unknown">>, <<"cases/decorator_member_unknown">>, <<"">>), [{std@compiler@@Diagnostic, <<"unknown-associated-fn">>, <<"unknown-associated-fn: `City` has no associated fn `revisions`">>, <<"src/main.bp">>, 23, 16, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_7'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_7'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_7'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_7'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_8'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_meta_on_member">>, <<"cases/decorator_meta_on_member">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-meta-on-member">>, <<"decorator-meta-on-member: `#[column]` on the field `name` calls `decl.setMeta`, and meta describes a top-level declaration">>, <<"src/main.bp">>, 11, 13, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_meta_on_member">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_meta_on_member">>, <<"cases/decorator_meta_on_member">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-meta-on-member">>, <<"decorator-meta-on-member: `#[column]` on the field `name` calls `decl.setMeta`, and meta describes a top-level declaration">>, <<"src/main.bp">>, 11, 13, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_8'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_8'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_8'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_8'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_9'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_all_arguments">>, <<"cases/typeinfo_all_arguments">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-all-arguments">>, <<"typeinfo-all-arguments: `@TypeInfo.all` takes labelled arguments, and this one has none">>, <<"src/main.bp">>, 11, 11, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"typeinfo_all_arguments">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_all_arguments">>, <<"cases/typeinfo_all_arguments">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-all-arguments">>, <<"typeinfo-all-arguments: `@TypeInfo.all` takes labelled arguments, and this one has none">>, <<"src/main.bp">>, 11, 11, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_9'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_9'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_9'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_9'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_10'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_all_mixed">>, <<"cases/typeinfo_all_mixed">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-all-mixed">>, <<"typeinfo-all-mixed: `#[tagged]` is carried by the function `job` and by the type `Box`, and one query answers one kind of value">>, <<"src/main.bp">>, 19, 11, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"typeinfo_all_mixed">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_all_mixed">>, <<"cases/typeinfo_all_mixed">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-all-mixed">>, <<"typeinfo-all-mixed: `#[tagged]` is carried by the function `job` and by the type `Box`, and one query answers one kind of value">>, <<"src/main.bp">>, 19, 11, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_10'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_10'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_10'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_10'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_11'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_all_needs_member">>, <<"cases/typeinfo_all_needs_member">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-all-needs-member">>, <<"typeinfo-all-needs-member: `#[component]` is carried by the type `Box`, and a type is no value: name the associated fn each entry calls">>, <<"src/main.bp">>, 16, 11, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"typeinfo_all_needs_member">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_all_needs_member">>, <<"cases/typeinfo_all_needs_member">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-all-needs-member">>, <<"typeinfo-all-needs-member: `#[component]` is carried by the type `Box`, and a type is no value: name the associated fn each entry calls">>, <<"src/main.bp">>, 16, 11, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_11'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_11'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_11'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_11'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_12'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_unknown_declaration">>, <<"cases/typeinfo_unknown_declaration">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-unknown-declaration">>, <<"typeinfo-unknown-declaration: `@typeInfo` reflects a declaration this module declares or imports, and this names none">>, <<"src/main.bp">>, 7, 38, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"typeinfo_unknown_declaration">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_unknown_declaration">>, <<"cases/typeinfo_unknown_declaration">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-unknown-declaration">>, <<"typeinfo-unknown-declaration: `@typeInfo` reflects a declaration this module declares or imports, and this names none">>, <<"src/main.bp">>, 7, 38, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_12'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_12'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_12'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_12'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_13'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_all_imported">>, <<"cases/typeinfo_all_imported">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-all-imported">>, <<"typeinfo-all-imported: `catalog` reads `@TypeInfo.all`, so it answers for the whole program and no module imports it">>, <<"src/main.bp">>, 7, 9, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"typeinfo_all_imported">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_all_imported">>, <<"cases/typeinfo_all_imported">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-all-imported">>, <<"typeinfo-all-imported: `catalog` reads `@TypeInfo.all`, so it answers for the whole program and no module imports it">>, <<"src/main.bp">>, 7, 9, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_13'() ->
    case persistent_term:get({decorator_four_output_places_216@main, '__bp_init_13'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_13'(), persistent_term:put({decorator_four_output_places_216@main, '__bp_init_13'}, __BpV), __BpV;
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
                    undefined -> erlang:spawn(decorator_four_output_places_216@main, '__bp_ets_owner', [Name, Seed]);
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
