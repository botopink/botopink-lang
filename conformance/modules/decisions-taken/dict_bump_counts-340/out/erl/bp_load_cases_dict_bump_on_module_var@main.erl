-module(bp_load_cases_dict_bump_on_module_var@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, '__bp_ets_owner'/2, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__counts'/0, '__bp_priv____bp_tab_counts'/0, '__bp_priv__worker'/1, '__bp_priv____bp_ets'/2]).

%%% Decisions 340 and 547 (ii) — `counts = counts.bump(k, n)` on a module `var` is a plain

%%% `Dict.bump`, and an `x = f(x)`: atomic on the BEAM, so two processes bumping the SAME key

%%% 2 000 times each, by 1 and by 2, lose none (`6000`); a key with no entry counts from 0,

%%% the seed's from its seed (`10 + 5`), and a key never bumped reads `null`.

%% import async, Dict

%% var counts — beamMemory(.Ets)
counts() ->
    std@beam:etsGet('__bp_tab_counts'(), bp_load_cases_dict_bump_on_module_var@main@@counts, 2).

'__bp_tab_counts'() ->
    case erlang:whereis(bp_load_cases_dict_bump_on_module_var@main@@counts) of
        undefined -> '__bp_ets'(bp_load_cases_dict_bump_on_module_var@main@@counts, std@collections@@Dict:ofEntries([{<<"seed">>, 10}]));
        _ -> bp_load_cases_dict_bump_on_module_var@main@@counts
    end.

%% @Async — eager lowering
worker(By) ->
    I = 0,
    I@3 = (fun __BpLoop(I@1) ->
        case (I@1 < 2000) of
            true ->
                I@2 = '__bp_int'(I@1 + 1, -2147483648, 2147483647, <<"integer overflow: += on i32 at src/main.bp:13:9">>),
                std@beam:etsSwap('__bp_tab_counts'(), fun(Counts) ->
                    std@collections@@Dict:bump(Counts, <<"hot">>, By)
                end),
                __BpLoop(I@2);
            _ -> I@1
        end
    end)(I),
    I@3.

%% @Async — eager lowering
main() ->
    Done = std@async:runAll([fun() ->
        worker(1)
    end, fun() ->
        worker(2)
    end]),
    std@beam:etsSwap('__bp_tab_counts'(), fun(Counts) ->
        std@collections@@Dict:bump(Counts, <<"seed">>, 5)
    end),
    '__bp_print'([Done]),
    '__bp_print'([std@collections@@Dict:at(counts(), <<"hot">>), std@collections@@Dict:at(counts(), <<"seed">>), std@collections@@Dict:at(counts(), <<"none">>)]).

%% @Async — eager lowering
'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

%% @Async — eager lowering
'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/dict_bump_on_module_var|*">>.

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
                    undefined -> erlang:spawn(bp_load_cases_dict_bump_on_module_var@main, '__bp_ets_owner', [Name, Seed]);
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

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'_botopink_init'() ->
    std@beam:etsPut('__bp_tab_counts'(), {bp_load_cases_dict_bump_on_module_var@main@@counts, std@collections@@Dict:ofEntries([{<<"seed">>, 10}])}),
    counts(),
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

'__bp_priv__counts'() -> counts().

'__bp_priv____bp_tab_counts'() -> '__bp_tab_counts'().

'__bp_priv__worker'(A0) -> worker(A0).

'__bp_priv____bp_ets'(A0, A1) -> '__bp_ets'(A0, A1).
