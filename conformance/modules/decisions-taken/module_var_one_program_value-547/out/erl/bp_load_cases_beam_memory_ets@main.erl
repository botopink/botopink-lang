-module(bp_load_cases_beam_memory_ets@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, '__bp_ets_owner'/2, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__hits'/0, '__bp_priv____bp_tab_hits'/0, '__bp_priv__request'/0, '__bp_priv____bp_ets'/2]).

%%% Decision 39's fixture — five requests, each its own process, three

%%% increments each, on one `#[compiler.beamMemory(.Ets)]` var: `15`. Without the

%%% registered owner the table died with the request that created it, every

%%% request read `3` and the counter ended at `0`. `hits = hits + 1` and

%%% `hits += 1` read the `var` they write: the compare-and-swap (decision 547

%%% (ii)). The per-request reads are not printed: their order is the scheduler's.

%% import async

%% var hits — beamMemory(.Ets)
hits() ->
    std@beam:etsGet('__bp_tab_hits'(), bp_load_cases_beam_memory_ets@main@@hits, 2).

'__bp_tab_hits'() ->
    case erlang:whereis(bp_load_cases_beam_memory_ets@main@@hits) of
        undefined -> '__bp_ets'(bp_load_cases_beam_memory_ets@main@@hits, 0);
        _ -> bp_load_cases_beam_memory_ets@main@@hits
    end.

%% @Async — eager lowering
request() ->
    std@beam:etsSwap('__bp_tab_hits'(), fun(Hits) ->
        '__bp_int'((Hits + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:14:17">>)
    end),
    std@beam:etsSwap('__bp_tab_hits'(), fun(Hits) ->
        '__bp_int'((Hits + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:15:17">>)
    end),
    std@beam:etsSwap('__bp_tab_hits'(), fun(Hits) ->
        '__bp_int'((Hits + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:16:5">>)
    end),
    0.

%% @Async — eager lowering
main() ->
    Done = std@async:runAll([fun() ->
        request()
    end, fun() ->
        request()
    end, fun() ->
        request()
    end, fun() ->
        request()
    end, fun() ->
        request()
    end]),
    '__bp_print'([erlang:length(Done)]),
    '__bp_print'([hits()]).

%% @Async — eager lowering
'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

%% @Async — eager lowering
'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/beam_memory_ets|*">>.

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
                    undefined -> erlang:spawn(bp_load_cases_beam_memory_ets@main, '__bp_ets_owner', [Name, Seed]);
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
    std@beam:etsPut('__bp_tab_hits'(), {bp_load_cases_beam_memory_ets@main@@hits, 0}),
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

'__bp_priv__hits'() -> hits().

'__bp_priv____bp_tab_hits'() -> '__bp_tab_hits'().

'__bp_priv__request'() -> request().

'__bp_priv____bp_ets'(A0, A1) -> '__bp_ets'(A0, A1).
