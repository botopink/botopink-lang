-module(bp_load_cases_context_behavior_implemented_indirectly@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, repoContext/0, '__bp_priv__Lookup'/0, '__bp_priv__Root'/0]).

%% import bpScopePush__, bpScopeFind__, bpScopeRendered__, bpScopeValue__, bpScopeRoot__

%%% Decision 416 (2) — `createContext(value, B)` takes a value whose type

%%% implements `B` through a behavior that `extends` `B` (`CachedRepository

%%% implement Cached`, `Cached extends Repository`), as a parameter typed `B`

%%% does; it is read back with `use context(repoContext)`.

%% import RenderScope, createContext, provide, context

%% type View: text

%% behavior Repository

%% behavior Cached

%% type CachedRepository: prefix

%% type Memory: tag

repoContext() ->
    case persistent_term:get({bp_load_cases_context_behavior_implemented_indirectly@main, repoContext}, '__bp_unset') of
        '__bp_unset' -> __BpV = {bp_load_cases_context_behavior_implemented_indirectly@main@@CachedRepository, <<"cached-">>}, persistent_term:put({bp_load_cases_context_behavior_implemented_indirectly@main, repoContext}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'Lookup'() ->
    fun(BpScope__) ->
        R = std@context:find(BpScope__, <<"Repository">>, repoContext()),
        std@context:rendered({bp_load_cases_context_behavior_implemented_indirectly@main@@View, '__bp_method'(fetch, R, [1])}, BpScope__)
    end.

'Root'() ->
    fun(BpScope__) ->
        BpScopeKids__0 = std@context:push(BpScope__, <<"Repository">>, {bp_load_cases_context_behavior_implemented_indirectly@main@@Memory, <<"mem">>}),
        L = std@context:valueOf(('Lookup'())(BpScopeKids__0)),
        std@context:rendered({bp_load_cases_context_behavior_implemented_indirectly@main@@View, erlang:element(2, L)}, BpScopeKids__0)
    end.

%% @Async — eager lowering
main() ->
    Outside = '__bp_field'((('Lookup'())(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, Outside)]),
    Inside = '__bp_field'((('Root'())(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, Inside)]).

%% @Async — eager lowering
'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

%% @Async — eager lowering
'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/context_behavior_implemented_indirectly|*">>.

'__bp_field'(V, F) when erlang:is_map(V) -> maps:get(F, V);
'__bp_field'(V, F) -> erlang:apply(erlang:element(1, V), '__bp_get', [V, F]).

'__bp_method'(M, V, Args) when erlang:is_map(V) -> erlang:apply(maps:get(M, V), [V | Args]);
'__bp_method'(M, V, Args) ->
    T = case erlang:is_tuple(V) of true -> erlang:element(1, V); false -> V end,
    O = case string:split(erlang:atom_to_list(T), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> T end,
    erlang:apply(O, M, [V | Args]).

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
    persistent_term:erase({bp_load_cases_context_behavior_implemented_indirectly@main, repoContext}),
    repoContext(),
    ok.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '_botopink_init'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__Lookup'() -> 'Lookup'().

'__bp_priv__Root'() -> 'Root'().
