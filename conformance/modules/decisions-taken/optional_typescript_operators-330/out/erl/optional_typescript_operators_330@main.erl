-module(optional_typescript_operators_330@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, '__bp_ets_owner'/2, '__bp_loaded'/2, '__bp_load_module'/3, '__bp_run'/1, '__bp_run_async'/1, '__bp_run_none'/0, '__bp_run_async_none'/0, '__bp_executor_0'/0, '__bp_executor_1'/0, '__bp_executor_2'/0, '__bp_executor_3'/0, '__bp_executor_4'/0, '__bp_executor_5'/0, '__bp_executor_6'/0, '__bp_executor_7'/0, '__bp_executor_8'/0, '__bp_executor_9'/0, '__bp_executor_10'/0, '__bp_executor_11'/0, '__bp_executor_12'/0, '__bp_executor_13'/0, '__bp_executor_14'/0, '__bp_executor_15'/0, '__bp_executor_16'/0, '__bp_executor_17'/0, '__bp_executor_18'/0, '__bp_executor_19'/0, '__bp_executor_20'/0, '__bp_executor_21'/0, '__bp_executor_22'/0, '__bp_executor_23'/0, '__bp_executor_24'/0, '__bp_executor_25'/0, '__bp_executor_26'/0, '__bp_executor_27'/0, '__bp_executor_28'/0, '__bp_executor_29'/0, main/0, accepted/0, '__bp_comptime_0_at'/0, '__bp_init_0'/0, '__bp_init_1'/0, '__bp_init_2'/0, '__bp_init_3'/0, '__bp_init_4'/0, '__bp_init_5'/0, '__bp_init_6'/0, '__bp_init_7'/0, '__bp_init_8'/0, '__bp_init_9'/0, '__bp_init_10'/0, '__bp_init_11'/0, '__bp_init_12'/0, '__bp_init_13'/0, '__bp_init_14'/0, '__bp_init_15'/0, '__bp_init_16'/0, '__bp_init_17'/0, '__bp_init_18'/0, '__bp_init_19'/0, '__bp_init_20'/0, '__bp_init_21'/0, '__bp_init_22'/0, '__bp_init_23'/0, '__bp_init_24'/0, '__bp_init_25'/0, '__bp_init_26'/0, '__bp_init_27'/0, '__bp_init_28'/0, '__bp_init_29'/0, '__bp_priv__answers'/0, '__bp_priv____bp_tab_answers'/0, '__bp_priv__string_slice'/3, '__bp_priv____bp_ets'/2]).

%% import RunFailureKind

%% type Asset: path, bytes, size, hash

%% behavior string

%% import __bp_run__bp_load__cases__optional_enum_method_call

%% import __bp_run__bp_load__cases__optional_float_function_value

%% import __bp_run__bp_load__cases__optional_if_null_initializer

%% import __bp_run__bp_load__cases__optional_member_default

%% import __bp_run__bp_load__cases__optional_method_absent_receiver

%% import __bp_run__bp_load__cases__optional_operators

%% import __bp_run__bp_load__cases__optional_record_method_absent_receiver

%% import __bp_run__bp_load__cases__std_type_field_associated

%% import __bp_run__bp_load__cases__nullish_default_namespace_call

%% import __bp_run__bp_load__cases__nullish_optional_call_default

%% import __bp_run__bp_load__cases__optional_array_at_record

%% import __bp_run__bp_load__cases__optional_call_operator

%% import __bp_run__bp_load__cases__optional_call_param_wasm

%% import __bp_run__bp_load__cases__optional_call_plain_answers

%% import __bp_run__bp_load__cases__optional_chain_absent_array_length

%% import __bp_run__bp_load__cases__optional_chain_field_after_call

%% import __bp_run__bp_load__cases__optional_chain_lambda_array_method

%% import __bp_run__bp_load__cases__optional_chain_lambda_generic

%% import __bp_run__bp_load__cases__optional_chain_nested_array

%% import __bp_run__bp_load__cases__optional_chain_present_array_length

%% import __bp_run__bp_load__cases__optional_chain_record_fields

%% import __bp_run__bp_load__cases__optional_enum_method_absent_receiver

%% import __bp_run__bp_load__cases__optional_index_record_field

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

%% import __bp_ns_adapter__buildOutput, __bp_ns_adapter__ranOf, __bp_ns_adapter__frames, __bp_ns_adapter__target, __bp_ns_candidate__finish, __bp_ns_observe__refusalOf, __bp_ns_observe__ranAnswer, __bp_ns_observe__refusedAnswer

%% The snapshot, read as a build input (decision 989 (5)).

accepted() ->
    <<"botopink-cell 2\n">>.

%% What each case answered, in the order the cases ran.

%% var answers — beamMemory(.Ets)
answers() ->
    std@beam:etsGet('__bp_tab_answers'(), optional_typescript_operators_330@main@@answers, 2).

'__bp_tab_answers'() ->
    case erlang:whereis(optional_typescript_operators_330@main@@answers) of
        undefined -> '__bp_ets'(optional_typescript_operators_330@main@@answers, []);
        _ -> optional_typescript_operators_330@main@@answers
    end.

%% One case, expanded where it is called (decision 808 (2)): a refused load answers its

%% diagnostics, a loaded one runs and answers its output.

'__bp_comptime_0_at'() ->
    0.

'__bp_executor_0'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_enum_method_call@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_enum_method_call">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_enum_method_call">>, <<"cases/optional_enum_method_call">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_0'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_0'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_0'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_0'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_1'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_float_function_value@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_float_function_value">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_float_function_value">>, <<"cases/optional_float_function_value">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_1'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_1'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_1'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_1'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_2'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_if_null_initializer@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_if_null_initializer">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_if_null_initializer">>, <<"cases/optional_if_null_initializer">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_2'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_2'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_2'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_2'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_3'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_member_default@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_member_default">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_member_default">>, <<"cases/optional_member_default">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_3'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_3'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_3'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_3'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_4'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_method_absent_receiver@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_method_absent_receiver">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_method_absent_receiver">>, <<"cases/optional_method_absent_receiver">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_4'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_4'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_4'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_4'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_5'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_operators@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_operators">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_operators">>, <<"cases/optional_operators">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_5'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_5'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_5'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_5'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_6'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_record_method_absent_receiver@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_record_method_absent_receiver">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_record_method_absent_receiver">>, <<"cases/optional_record_method_absent_receiver">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_6'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_6'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_6'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_6'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_7'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_std_type_field_associated@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"std_type_field_associated">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"std_type_field_associated">>, <<"cases/std_type_field_associated">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_7'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_7'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_7'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_7'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_8'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"assoc_type_named_like_member">>, <<"cases/assoc_type_named_like_member">>, <<"">>), [{std@compiler@@Diagnostic, <<"assoc-type-duplicate">>, <<"a type declared in a type's body is named through it, and this name is already a member of it">>, <<"src/main.bp">>, 12, 14, <<"`Owner.Name` names one thing">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"assoc_type_named_like_member">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"assoc_type_named_like_member">>, <<"cases/assoc_type_named_like_member">>, <<"">>), [{std@compiler@@Diagnostic, <<"assoc-type-duplicate">>, <<"a type declared in a type's body is named through it, and this name is already a member of it">>, <<"src/main.bp">>, 12, 14, <<"`Owner.Name` names one thing">>, []}]}))), Refusals@3)])
    end).

'__bp_init_8'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_8'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_8'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_8'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_9'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"bang_never_null">>, <<"cases/bang_never_null">>, <<"">>), [{std@compiler@@Diagnostic, <<"optional-operator-never-null">>, <<"optional-operator-never-null: `!` over a value that is never null \x{E2}\x{80}\x{94} this is `i32`, not `?i32`">>, <<"src/main.bp">>, 8, 12, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"bang_never_null">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"bang_never_null">>, <<"cases/bang_never_null">>, <<"">>), [{std@compiler@@Diagnostic, <<"optional-operator-never-null">>, <<"optional-operator-never-null: `!` over a value that is never null \x{E2}\x{80}\x{94} this is `i32`, not `?i32`">>, <<"src/main.bp">>, 8, 12, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_9'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_9'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_9'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_9'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_10'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"nullish_beside_logical">>, <<"cases/nullish_beside_logical">>, <<"">>), [{std@compiler@@Diagnostic, <<"nullish-beside-logical">>, <<"`??` beside `&&` or `||` takes parentheses">>, <<"src/main.bp">>, 11, 22, <<"parenthesise the `??` or the logical operand">>, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"nullish_beside_logical">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"nullish_beside_logical">>, <<"cases/nullish_beside_logical">>, <<"">>), [{std@compiler@@Diagnostic, <<"nullish-beside-logical">>, <<"`??` beside `&&` or `||` takes parentheses">>, <<"src/main.bp">>, 11, 22, <<"parenthesise the `??` or the logical operand">>, []}]}))), Refusals@3)])
    end).

'__bp_init_10'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_10'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_10'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_10'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_11'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"nullish_never_null">>, <<"cases/nullish_never_null">>, <<"">>), [{std@compiler@@Diagnostic, <<"optional-operator-never-null">>, <<"optional-operator-never-null: `??` over a value that is never null \x{E2}\x{80}\x{94} this is `string`, not `?string`">>, <<"src/main.bp">>, 8, 13, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"nullish_never_null">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"nullish_never_null">>, <<"cases/nullish_never_null">>, <<"">>), [{std@compiler@@Diagnostic, <<"optional-operator-never-null">>, <<"optional-operator-never-null: `??` over a value that is never null \x{E2}\x{80}\x{94} this is `string`, not `?string`">>, <<"src/main.bp">>, 8, 13, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_11'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_11'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_11'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_11'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_12'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"optional_has_no_methods">>, <<"cases/optional_has_no_methods">>, <<"">>), [{std@compiler@@Diagnostic, <<"optional-has-no-methods">>, <<"optional-has-no-methods: unknown method `unwrapOr` on `?string` \x{E2}\x{80}\x{94} an optional has no methods">>, <<"src/main.bp">>, 11, 21, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"optional_has_no_methods">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"optional_has_no_methods">>, <<"cases/optional_has_no_methods">>, <<"">>), [{std@compiler@@Diagnostic, <<"optional-has-no-methods">>, <<"optional-has-no-methods: unknown method `unwrapOr` on `?string` \x{E2}\x{80}\x{94} an optional has no methods">>, <<"src/main.bp">>, 11, 21, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_12'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_12'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_12'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_12'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_13'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"optional_operator_never_null">>, <<"cases/optional_operator_never_null">>, <<"">>), [{std@compiler@@Diagnostic, <<"optional-operator-never-null">>, <<"optional-operator-never-null: `?.` over a value that is never null \x{E2}\x{80}\x{94} this is `string`, not `?string`">>, <<"src/main.bp">>, 9, 14, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"optional_operator_never_null">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"optional_operator_never_null">>, <<"cases/optional_operator_never_null">>, <<"">>), [{std@compiler@@Diagnostic, <<"optional-operator-never-null">>, <<"optional-operator-never-null: `?.` over a value that is never null \x{E2}\x{80}\x{94} this is `string`, not `?string`">>, <<"src/main.bp">>, 9, 14, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_13'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_13'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_13'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_13'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_14'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"result_namespace_removed">>, <<"cases/result_namespace_removed">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"unbound variable 'result'">>, <<"src/main.bp">>, 13, 11, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"result_namespace_removed">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"result_namespace_removed">>, <<"cases/result_namespace_removed">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"unbound variable 'result'">>, <<"src/main.bp">>, 13, 11, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_14'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_14'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_14'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_14'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_15'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_nullish_default_namespace_call@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"nullish_default_namespace_call">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"nullish_default_namespace_call">>, <<"cases/nullish_default_namespace_call">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_15'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_15'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_15'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_15'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_16'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_nullish_optional_call_default@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"nullish_optional_call_default">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"nullish_optional_call_default">>, <<"cases/nullish_optional_call_default">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_16'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_16'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_16'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_16'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_17'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_array_at_record@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_array_at_record">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_array_at_record">>, <<"cases/optional_array_at_record">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_17'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_17'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_17'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_17'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_18'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_call_operator@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_call_operator">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_call_operator">>, <<"cases/optional_call_operator">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_18'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_18'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_18'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_18'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_19'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_call_param_wasm@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_call_param_wasm">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_call_param_wasm">>, <<"cases/optional_call_param_wasm">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_19'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_19'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_19'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_19'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_20'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_call_plain_answers@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_call_plain_answers">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_call_plain_answers">>, <<"cases/optional_call_plain_answers">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_20'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_20'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_20'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_20'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_21'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_chain_absent_array_length@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_chain_absent_array_length">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_chain_absent_array_length">>, <<"cases/optional_chain_absent_array_length">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_21'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_21'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_21'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_21'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_22'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_chain_field_after_call@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_chain_field_after_call">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_chain_field_after_call">>, <<"cases/optional_chain_field_after_call">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_22'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_22'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_22'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_22'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_23'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_chain_lambda_array_method@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_chain_lambda_array_method">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_chain_lambda_array_method">>, <<"cases/optional_chain_lambda_array_method">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_23'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_23'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_23'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_23'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_24'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_chain_lambda_generic@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_chain_lambda_generic">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_chain_lambda_generic">>, <<"cases/optional_chain_lambda_generic">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_24'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_24'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_24'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_24'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_25'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_chain_nested_array@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_chain_nested_array">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_chain_nested_array">>, <<"cases/optional_chain_nested_array">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_25'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_25'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_25'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_25'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_26'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_chain_present_array_length@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_chain_present_array_length">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_chain_present_array_length">>, <<"cases/optional_chain_present_array_length">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_26'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_26'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_26'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_26'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_27'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_chain_record_fields@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_chain_record_fields">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_chain_record_fields">>, <<"cases/optional_chain_record_fields">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_27'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_27'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_27'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_27'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_28'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_enum_method_absent_receiver@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_enum_method_absent_receiver">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_enum_method_absent_receiver">>, <<"cases/optional_enum_method_absent_receiver">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_28'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_28'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_28'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_28'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_29'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_optional_index_record_field@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"optional_index_record_field">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"optional_index_record_field">>, <<"cases/optional_index_record_field">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_29'() ->
    case persistent_term:get({optional_typescript_operators_330@main, '__bp_init_29'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_29'(), persistent_term:put({optional_typescript_operators_330@main, '__bp_init_29'}, __BpV), __BpV;
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
                    undefined -> erlang:spawn(optional_typescript_operators_330@main, '__bp_ets_owner', [Name, Seed]);
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
    '__bp_init_25'(),
    '__bp_init_26'(),
    '__bp_init_27'(),
    '__bp_init_28'(),
    '__bp_init_29'(),
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
