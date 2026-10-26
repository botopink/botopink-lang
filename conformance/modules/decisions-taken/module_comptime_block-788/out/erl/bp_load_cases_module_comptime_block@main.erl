-module(bp_load_cases_module_comptime_block@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, '__bp_executor_0'/0, main/0, '__bp_executor_1'/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_comptime_0_at'/0, '__bp_init_0'/0, '__bp_comptime_1_at'/0, '__bp_init_1'/0]).

%%% Decision 788 — two top-level `comptime` blocks run at build in the order

%%% written; `f`, whose every parameter is `comptime`, is expanded at each

%%% call, and the `compiler.init` it writes runs at program start, in the

%%% order the blocks registered it, before `main`.

% Expanded where a block calls it: its `print` is the build's output.

'__bp_comptime_0_at'() ->
    0.

'__bp_executor_0'() ->
    '__bp_print'([<<"init ", "a">>]).

'__bp_init_0'() ->
    case persistent_term:get({bp_load_cases_module_comptime_block@main, '__bp_init_0'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_0'(), persistent_term:put({bp_load_cases_module_comptime_block@main, '__bp_init_0'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

main() ->
    '__bp_print'([<<"main">>]).

'__bp_comptime_1_at'() ->
    0.

'__bp_executor_1'() ->
    '__bp_print'([<<"init ", "b">>]).

'__bp_init_1'() ->
    case persistent_term:get({bp_load_cases_module_comptime_block@main, '__bp_init_1'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_1'(), persistent_term:put({bp_load_cases_module_comptime_block@main, '__bp_init_1'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/module_comptime_block|*">>.

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
    persistent_term:erase({bp_load_cases_module_comptime_block@main, '__bp_init_0'}),
    persistent_term:erase({bp_load_cases_module_comptime_block@main, '__bp_init_1'}),
    '__bp_init_0'(),
    '__bp_init_1'(),
    ok.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '_botopink_init'(),
    main().

main(_Args) ->
    '_botopink_main'().
