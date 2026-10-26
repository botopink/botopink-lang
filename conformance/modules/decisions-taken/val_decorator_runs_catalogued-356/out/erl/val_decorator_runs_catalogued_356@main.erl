-module(val_decorator_runs_catalogued_356@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, '__bp_ets_owner'/2, '__bp_loaded'/2, '__bp_load_module'/3, '__bp_run'/1, '__bp_run_async'/1, '__bp_run_none'/0, '__bp_run_async_none'/0, '__bp_executor_0'/0, '__bp_executor_1'/0, '__bp_executor_2'/0, '__bp_executor_3'/0, '__bp_executor_4'/0, '__bp_executor_5'/0, main/0, accepted/0, '__bp_comptime_0_at'/0, '__bp_init_0'/0, '__bp_init_1'/0, '__bp_init_2'/0, '__bp_init_3'/0, '__bp_init_4'/0, '__bp_init_5'/0, '__bp_priv__answers'/0, '__bp_priv____bp_tab_answers'/0, '__bp_priv__string_slice'/3, '__bp_priv____bp_ets'/2]).

%% import RunFailureKind

%% type Asset: path, bytes, size, hash

%% behavior string

%% import __bp_run__bp_load__cases__val_decorator_catalogue

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

%% import __bp_ns_adapter__frames, __bp_ns_adapter__ranOf, __bp_ns_adapter__buildOutput, __bp_ns_adapter__target, __bp_ns_candidate__finish, __bp_ns_observe__refusedAnswer, __bp_ns_observe__refusalOf, __bp_ns_observe__ranAnswer

%% The snapshot, read as a build input (decision 989 (5)).

accepted() ->
    <<"botopink-cell 2\n">>.

%% What each case answered, in the order the cases ran.

%% var answers — beamMemory(.Ets)
answers() ->
    std@beam:etsGet('__bp_tab_answers'(), val_decorator_runs_catalogued_356@main@@answers, 2).

'__bp_tab_answers'() ->
    case erlang:whereis(val_decorator_runs_catalogued_356@main@@answers) of
        undefined -> '__bp_ets'(val_decorator_runs_catalogued_356@main@@answers, []);
        _ -> val_decorator_runs_catalogued_356@main@@answers
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
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_all_val_and_fn">>, <<"cases/typeinfo_all_val_and_fn">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-all-mixed">>, <<"typeinfo-all-mixed: `#[tag]` is carried by the function `twice` and by the val `limit`, and one query answers one kind of value">>, <<"src/main.bp">>, 20, 11, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"typeinfo_all_val_and_fn">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"typeinfo_all_val_and_fn">>, <<"cases/typeinfo_all_val_and_fn">>, <<"">>), [{std@compiler@@Diagnostic, <<"typeinfo-all-mixed">>, <<"typeinfo-all-mixed: `#[tag]` is carried by the function `twice` and by the val `limit`, and one query answers one kind of value">>, <<"src/main.bp">>, 20, 11, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_0'() ->
    case persistent_term:get({val_decorator_runs_catalogued_356@main, '__bp_init_0'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_0'(), persistent_term:put({val_decorator_runs_catalogued_356@main, '__bp_init_0'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_1'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"val_decorator_add_member">>, <<"cases/val_decorator_add_member">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-member-without-type">>, <<"decorator-member-without-type: `#[helper]` on the val `limit` calls `decl.addMember`, and a member belongs to a type">>, <<"src/main.bp">>, 12, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"val_decorator_add_member">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"val_decorator_add_member">>, <<"cases/val_decorator_add_member">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-member-without-type">>, <<"decorator-member-without-type: `#[helper]` on the val `limit` calls `decl.addMember`, and a member belongs to a type">>, <<"src/main.bp">>, 12, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_1'() ->
    case persistent_term:get({val_decorator_runs_catalogued_356@main, '__bp_init_1'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_1'(), persistent_term:put({val_decorator_runs_catalogued_356@main, '__bp_init_1'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_2'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"val_decorator_add_type">>, <<"cases/val_decorator_add_type">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-type-without-owner">>, <<"decorator-type-without-owner: `#[helper]` on the val `limit` calls `decl.addType`, and an associated type belongs to a type">>, <<"src/main.bp">>, 10, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"val_decorator_add_type">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"val_decorator_add_type">>, <<"cases/val_decorator_add_type">>, <<"">>), [{std@compiler@@Diagnostic, <<"decorator-type-without-owner">>, <<"decorator-type-without-owner: `#[helper]` on the val `limit` calls `decl.addType`, and an associated type belongs to a type">>, <<"src/main.bp">>, 10, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_2'() ->
    case persistent_term:get({val_decorator_runs_catalogued_356@main, '__bp_init_2'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_2'(), persistent_term:put({val_decorator_runs_catalogued_356@main, '__bp_init_2'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_3'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"val_decorator_on_var">>, <<"cases/val_decorator_on_var">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"`#[mark]` annotates the module `var` `count`, and a decorator runs on a `val`, never on a `var`">>, <<"src/main.bp">>, 11, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"val_decorator_on_var">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"val_decorator_on_var">>, <<"cases/val_decorator_on_var">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"`#[mark]` annotates the module `var` `count`, and a decorator runs on a `val`, never on a `var`">>, <<"src/main.bp">>, 11, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_3'() ->
    case persistent_term:get({val_decorator_runs_catalogued_356@main, '__bp_init_3'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_3'(), persistent_term:put({val_decorator_runs_catalogued_356@main, '__bp_init_3'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_4'() ->
    Refusals = [],
    Refusals@3 = lists:foldl(fun(D, Refusals@1) ->
        Refusals@2 = (Refusals@1 ++ [conformance_lib@observe:refusalOf(erlang:element(2, D), erlang:element(3, D), erlang:element(4, D), erlang:element(5, D), erlang:element(6, D), erlang:element(7, D), conformance_lib@adapter:frames(D))]),
        Refusals@2
    end, Refusals, erlang:element(3, ({std@compiler@@Refused, '__bp_load_module'(<<"val_decorator_runs">>, <<"cases/val_decorator_runs">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"#[mark] ran on the val one">>, <<"src/main.bp">>, 11, 3, undefined, []}]}))),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:refusedAnswer(<<"val_decorator_runs">>, conformance_lib@adapter:buildOutput(erlang:element(2, ({std@compiler@@Refused, '__bp_load_module'(<<"val_decorator_runs">>, <<"cases/val_decorator_runs">>, <<"">>), [{std@compiler@@Diagnostic, <<"">>, <<"#[mark] ran on the val one">>, <<"src/main.bp">>, 11, 3, undefined, []}]}))), Refusals@3)])
    end).

'__bp_init_4'() ->
    case persistent_term:get({val_decorator_runs_catalogued_356@main, '__bp_init_4'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_4'(), persistent_term:put({val_decorator_runs_catalogued_356@main, '__bp_init_4'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_5'() ->
    Ran = conformance_lib@adapter:ranOf('__bp_run'(fun bp_load_cases_val_decorator_catalogue@main:'__bp_loaded_main'/0)),
    std@beam:etsSwap('__bp_tab_answers'(), fun(Answers) ->
        (Answers ++ [conformance_lib@observe:ranAnswer(<<"val_decorator_catalogue">>, conformance_lib@adapter:buildOutput(('__bp_load_module'(<<"val_decorator_catalogue">>, <<"cases/val_decorator_catalogue">>, <<"">>))), '__bp_field'(Ran, printed), '__bp_field'(Ran, failed), '__bp_field'(Ran, failure))])
    end).

'__bp_init_5'() ->
    case persistent_term:get({val_decorator_runs_catalogued_356@main, '__bp_init_5'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_5'(), persistent_term:put({val_decorator_runs_catalogued_356@main, '__bp_init_5'}, __BpV), __BpV;
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
                    undefined -> erlang:spawn(val_decorator_runs_catalogued_356@main, '__bp_ets_owner', [Name, Seed]);
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
