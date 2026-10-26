-module(bp_load_cases_closure_capture_statement_position@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, '__bp_ets_owner'/2, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__hits'/0, '__bp_priv____bp_tab_hits'/0, '__bp_priv__run'/2, '__bp_priv____bp_ets'/2]).

%%% Decision 148 (lg-b) — the two shapes that may write a captured `var`: a

%%% `forEach` body, and a local closure called only at statement position

%%% (here also from inside a loop and a `forEach` body). A counter shared

%%% across calls is a module-level `var`, which any lambda may write.

%% var hits — beamMemory(.Ets)
hits() ->
    std@beam:etsGet('__bp_tab_hits'(), bp_load_cases_closure_capture_statement_position@main@@hits, 2).

'__bp_tab_hits'() ->
    case erlang:whereis(bp_load_cases_closure_capture_statement_position@main@@hits) of
        undefined -> '__bp_ets'(bp_load_cases_closure_capture_statement_position@main@@hits, 0);
        _ -> bp_load_cases_closure_capture_statement_position@main@@hits
    end.

run(F, X) ->
    '__bp_int'((F() + X), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:11:16">>).

main() ->
    N = lists:foldl(fun(X, N) ->
        '__bp_add'(N, X)
    end, 0, [1, 2, 3]),
    Bump = fun(N@1) ->
        N@2 = '__bp_int'((N@1 + 10), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:20:15">>),
        N@2
    end,
    N@3 = Bump(N),
    N@6 = lists:foldl(fun(I, N@4) ->
        N@5 = Bump(N@4),
        N@5
    end, N@3, [1, 2]),
    N@9 = lists:foldl(fun(V, N@7) ->
        N@8 = Bump(N@7),
        N@8
    end, N@6, [5]),
    '__bp_print'([N@9]),
    '__bp_print'([run(fun() ->
        std@beam:etsSwap('__bp_tab_hits'(), fun(Hits) ->
            '__bp_int'((Hits + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:30:25">>)
        end),
        1
    end, 0)]),
    '__bp_print'([hits()]).

'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/closure_capture_statement_position|*">>.

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
                    undefined -> erlang:spawn(bp_load_cases_closure_capture_statement_position@main, '__bp_ets_owner', [Name, Seed]);
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

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

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
    std@beam:etsPut('__bp_tab_hits'(), {bp_load_cases_closure_capture_statement_position@main@@hits, 0}),
    ok.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '_botopink_init'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__hits'() -> hits().

'__bp_priv____bp_tab_hits'() -> '__bp_tab_hits'().

'__bp_priv__run'(A0, A1) -> run(A0, A1).

'__bp_priv____bp_ets'(A0, A1) -> '__bp_ets'(A0, A1).
