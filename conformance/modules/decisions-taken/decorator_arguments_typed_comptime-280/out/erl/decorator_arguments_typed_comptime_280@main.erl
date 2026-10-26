-module(decorator_arguments_typed_comptime_280@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, '__bp_ets_owner'/2, '__bp_loaded'/2, '__bp_load_module'/3, '__bp_run'/1, '__bp_run_async'/1, '__bp_run_none'/0, '__bp_run_async_none'/0, '__bp_executor_0'/0, '__bp_executor_1'/0, '__bp_executor_2'/0, '__bp_executor_3'/0, '__bp_executor_4'/0, '__bp_executor_5'/0, '__bp_executor_6'/0, '__bp_executor_7'/0, '__bp_executor_8'/0, '__bp_executor_9'/0, '__bp_executor_10'/0, '__bp_executor_11'/0, '__bp_executor_12'/0, '__bp_executor_13'/0, '__bp_executor_14'/0, '__bp_executor_15'/0, '__bp_executor_16'/0, main/0, accepted/0, '__bp_comptime_0_at'/0, '__bp_init_0'/0, '__bp_init_1'/0, '__bp_init_2'/0, '__bp_init_3'/0, '__bp_init_4'/0, '__bp_init_5'/0, '__bp_init_6'/0, '__bp_init_7'/0, '__bp_init_8'/0, '__bp_init_9'/0, '__bp_init_10'/0, '__bp_init_11'/0, '__bp_init_12'/0, '__bp_init_13'/0, '__bp_init_14'/0, '__bp_init_15'/0, '__bp_init_16'/0, '__bp_priv__answers'/0, '__bp_priv____bp_tab_answers'/0, '__bp_priv__string_slice'/3, '__bp_priv____bp_ets'/2]).

%% import RunFailureKind

%% type Asset: path, bytes, size, hash

%% behavior string

%% import __bp_run__bp_load__cases__decorator_decl_pattern

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

%% import __bp_ns_adapter__frames, __bp_ns_adapter__buildOutput, __bp_ns_adapter__ranOf, __bp_ns_adapter__target, __bp_ns_candidate__finish, __bp_ns_observe__refusedAnswer, __bp_ns_observe__refusalOf, __bp_ns_observe__ranAnswer

%% The snapshot, read as a build input (decision 989 (5)).

accepted() ->
    <<"botopink-cell 2\n">>.

%% What each case answered, in the order the cases ran.

%% var answers — beamMemory(.Ets)
answers() ->
    std@beam:etsGet('__bp_tab_answers'(), decorator_arguments_typed_comptime_280@main@@answers, 2).

'__bp_tab_answers'() ->
    case erlang:whereis(decorator_arguments_typed_comptime_280@main@@answers) of
        undefined -> '__bp_ets'(decorator_arguments_typed_comptime_280@main@@answers, []);
        _ -> decorator_arguments_typed_comptime_280@main@@answers
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
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"comptime_arg_not_known">>, <<"cases/comptime_arg_not_known">>, <<"">>), [{std@compiler@@Diagnostic, <<"comptime-arg-not-known">>, <<"comptime-arg-not-known: `k` is a run-time value, and the parameter `n` is `comptime` \x{E2}\x{80}\x{94} its argument is known while the program compiles">>, <<"src/main.bp">>, 16, 17, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"comptime_arg_not_known">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"comptime_arg_not_known">>, <<"cases/comptime_arg_not_known">>, <<"">>), [{std@compiler@@Diagnostic, <<"comptime-arg-not-known">>, <<"comptime-arg-not-known: `k` is a run-time value, and the parameter `n` is `comptime` \x{E2}\x{80}\x{94} its argument is known while the program compiles">>, <<"src/main.bp">>, 16, 17, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_0'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_0'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_0'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_0'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_1'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"comptime_default_outside_decorator">>, <<"cases/comptime_default_outside_decorator">>, <<"">>), [{std@compiler@@Diagnostic, <<"comptime-default-outside-decorator">>, <<"comptime-default-outside-decorator: the `comptime` parameter `n` takes a default only in a decorator">>, <<"src/main.bp">>, 8, 36, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"comptime_default_outside_decorator">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"comptime_default_outside_decorator">>, <<"cases/comptime_default_outside_decorator">>, <<"">>), [{std@compiler@@Diagnostic, <<"comptime-default-outside-decorator">>, <<"comptime-default-outside-decorator: the `comptime` parameter `n` takes a default only in a decorator">>, <<"src/main.bp">>, 8, 36, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_1'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_1'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_1'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_1'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_2'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_arg_function_mismatch">>, <<"cases/decorator_arg_function_mismatch">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"type mismatch: `#[check]`'s `rule` expects `?fn(Account) -> bool`, got `fn(Order) -> bool`">>, <<"src/main.bp">>, 25, 21, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_arg_function_mismatch">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_arg_function_mismatch">>, <<"cases/decorator_arg_function_mismatch">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"type mismatch: `#[check]`'s `rule` expects `?fn(Account) -> bool`, got `fn(Order) -> bool`">>, <<"src/main.bp">>, 25, 21, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_2'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_2'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_2'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_2'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_3'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_arg_label_unknown">>, <<"cases/decorator_arg_label_unknown">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"`#[check]` has no parameter `where`">>, <<"src/main.bp">>, 18, 25, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_arg_label_unknown">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_arg_label_unknown">>, <<"cases/decorator_arg_label_unknown">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"`#[check]` has no parameter `where`">>, <<"src/main.bp">>, 18, 25, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_3'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_3'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_3'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_3'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_4'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_arg_unbound_function">>, <<"cases/decorator_arg_unbound_function">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"unbound variable 'passwordMatch'">>, <<"src/main.bp">>, 25, 29, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_arg_unbound_function">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_arg_unbound_function">>, <<"cases/decorator_arg_unbound_function">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"unbound variable 'passwordMatch'">>, <<"src/main.bp">>, 25, 29, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_4'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_4'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_4'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_4'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_5'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_argument_kind">>, <<"cases/decorator_argument_kind">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"type mismatch: `#[value]`'s `key` expects `string`, got `i32`">>, <<"src/main.bp">>, 9, 9, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_argument_kind">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_argument_kind">>, <<"cases/decorator_argument_kind">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"type mismatch: `#[value]`'s `key` expects `string`, got `i32`">>, <<"src/main.bp">>, 9, 9, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_5'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_5'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_5'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_5'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_6'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_check_without_rule_not_bool">>, <<"cases/decorator_check_without_rule_not_bool">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"#[check] without `rule` annotates an `fn(x) -> bool`">>, <<"src/main.bp">>, 24, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_check_without_rule_not_bool">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_check_without_rule_not_bool">>, <<"cases/decorator_check_without_rule_not_bool">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"#[check] without `rule` annotates an `fn(x) -> bool`">>, <<"src/main.bp">>, 24, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_6'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_6'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_6'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_6'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_7'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_decl_pattern_mismatch">>, <<"cases/decorator_decl_pattern_mismatch">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"`#[on]` expects a declaration of type `fn(E) -> unknown`, and `wrong` is `fn() -> void`">>, <<"src/main.bp">>, 11, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_decl_pattern_mismatch">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_decl_pattern_mismatch">>, <<"cases/decorator_decl_pattern_mismatch">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"`#[on]` expects a declaration of type `fn(E) -> unknown`, and `wrong` is `fn() -> void`">>, <<"src/main.bp">>, 11, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_7'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_7'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_7'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_7'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_8'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_decl_pattern_return">>, <<"cases/decorator_decl_pattern_return">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"`#[page]` expects a declaration of type `fn(Route<P>) -> View`, and `blog` is `fn(Route<string>) -> string`">>, <<"src/main.bp">>, 18, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_decl_pattern_return">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_decl_pattern_return">>, <<"cases/decorator_decl_pattern_return">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"`#[page]` expects a declaration of type `fn(Route<P>) -> View`, and `blog` is `fn(Route<string>) -> string`">>, <<"src/main.bp">>, 18, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_8'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_8'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_8'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_8'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_9'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_field_key_case">>, <<"cases/decorator_field_key_case">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"unknown field 'Code' on type 'City'">>, <<"src/main.bp">>, 14, 10, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_field_key_case">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_field_key_case">>, <<"cases/decorator_field_key_case">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"unknown field 'Code' on type 'City'">>, <<"src/main.bp">>, 14, 10, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_9'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_9'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_9'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_9'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_10'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_field_key_too_many">>, <<"cases/decorator_field_key_too_many">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"`#[unique]` on `City` expects 1 argument(s), got 2">>, <<"src/main.bp">>, 14, 17, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_field_key_too_many">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_field_key_too_many">>, <<"cases/decorator_field_key_too_many">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"`#[unique]` on `City` expects 1 argument(s), got 2">>, <<"src/main.bp">>, 14, 17, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_10'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_10'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_10'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_10'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_11'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_function_argument_mismatch">>, <<"cases/decorator_function_argument_mismatch">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"type mismatch: `#[page]`'s `paths` expects `?fn() -> BlogParams[]`, got `fn() -> User[]`">>, <<"src/main.bp">>, 27, 30, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_function_argument_mismatch">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_function_argument_mismatch">>, <<"cases/decorator_function_argument_mismatch">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"type mismatch: `#[page]`'s `paths` expects `?fn() -> BlogParams[]`, got `fn() -> User[]`">>, <<"src/main.bp">>, 27, 30, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_11'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_11'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_11'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_11'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_12'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_param_not_comptime">>, <<"cases/decorator_param_not_comptime">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-param-not-comptime">>, <<"decorator-param-not-comptime: the decorator `route`'s parameter `path` is not `comptime`">>, <<"src/main.bp">>, 8, 32, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_param_not_comptime">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_param_not_comptime">>, <<"cases/decorator_param_not_comptime">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-param-not-comptime">>, <<"decorator-param-not-comptime: the decorator `route`'s parameter `path` is not `comptime`">>, <<"src/main.bp">>, 8, 32, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_12'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_12'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_12'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_12'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_13'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_record_argument_mismatch">>, <<"cases/decorator_record_argument_mismatch">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"type mismatch: `#[cacheable]`'s `cache` expects `Cache<Product[]>`, got `Cache<User[]>`">>, <<"src/main.bp">>, 22, 13, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_record_argument_mismatch">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_record_argument_mismatch">>, <<"cases/decorator_record_argument_mismatch">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"type mismatch: `#[cacheable]`'s `cache` expects `Cache<Product[]>`, got `Cache<User[]>`">>, <<"src/main.bp">>, 22, 13, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_13'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_13'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_13'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_13'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_14'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_type_argument_unknown">>, <<"cases/decorator_type_argument_unknown">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"unknown type 'MailSendr'">>, <<"src/main.bp">>, 15, 28, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_type_argument_unknown">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_type_argument_unknown">>, <<"cases/decorator_type_argument_unknown">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"unknown type 'MailSendr'">>, <<"src/main.bp">>, 15, 28, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_14'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_14'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_14'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_14'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_15'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_variant_case">>, <<"cases/decorator_variant_case">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"`.custom` names no variant of `Code`">>, <<"src/main.bp">>, 19, 24, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"decorator_variant_case">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"decorator_variant_case">>, <<"cases/decorator_variant_case">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"`.custom` names no variant of `Code`">>, <<"src/main.bp">>, 19, 24, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_15'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_15'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_15'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_15'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_16'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_decorator_decl_pattern@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"decorator_decl_pattern">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"decorator_decl_pattern">>, <<"cases/decorator_decl_pattern">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_16'() ->
    case persistent_term:get({decorator_arguments_typed_comptime_280@main, '__bp_init_16'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_16'(), persistent_term:put({decorator_arguments_typed_comptime_280@main, '__bp_init_16'}, __BpV), __BpV;
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
                    undefined -> erlang:spawn(decorator_arguments_typed_comptime_280@main, '__bp_ets_owner', [Name, Seed]);
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
