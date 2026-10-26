-module(bp_load_cases_context_provide_made_in_body@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, themeContext/0, '__bp_priv__Label'/0, '__bp_priv__Dark'/0, '__bp_priv__Again'/0]).

%% import Context

%% import bpScopePush__, bpScopeFind__, bpScopeRendered__, bpScopeValue__, bpScopeRoot__

%%% Decision 723 — `use provide(ctx)` takes a context value alone: a

%%% component that provides another value makes a context of the same type

%%% in its body, `val c = comptime createContext(Theme(…));`, then `use

%%% provide(c)`. `Label` reads `use context(themeContext)`: under `Dark` the

%%% context `Dark` made, under `Again` the declared default provided again,

%%% with no provider the handle's default.

%% import RenderScope, createContext, provide, context

%% type Theme: mode

%% type Element: text

themeContext() ->
    case persistent_term:get({bp_load_cases_context_provide_made_in_body@main, themeContext}, '__bp_unset') of
        '__bp_unset' -> __BpV = {bp_load_cases_context_provide_made_in_body@main@@Theme, <<"light">>}, persistent_term:put({bp_load_cases_context_provide_made_in_body@main, themeContext}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'Label'() ->
    fun(BpScope__) ->
        T = std@context:find(BpScope__, <<"Theme">>, themeContext()),
        std@context:rendered({bp_load_cases_context_provide_made_in_body@main@@Element, erlang:element(2, T)}, BpScope__)
    end.

'Dark'() ->
    fun(BpScope__) ->
        C = {bp_load_cases_context_provide_made_in_body@main@@Theme, <<"dark">>},
        BpScopeKids__0 = std@context:push(BpScope__, <<"Theme">>, C),
        L = std@context:valueOf(('Label'())(BpScopeKids__0)),
        std@context:rendered({bp_load_cases_context_provide_made_in_body@main@@Element, erlang:element(2, L)}, BpScopeKids__0)
    end.

'Again'() ->
    fun(BpScope__) ->
        BpScopeKids__1 = std@context:push(BpScope__, <<"Theme">>, themeContext()),
        L = std@context:valueOf(('Label'())(BpScopeKids__1)),
        std@context:rendered({bp_load_cases_context_provide_made_in_body@main@@Element, erlang:element(2, L)}, BpScopeKids__1)
    end.

%% @Async — eager lowering
main() ->
    L = '__bp_field'((('Label'())(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, L)]),
    D = '__bp_field'((('Dark'())(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, D)]),
    A = '__bp_field'((('Again'())(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, A)]).

%% @Async — eager lowering
'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

%% @Async — eager lowering
'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/context_provide_made_in_body|*">>.

'__bp_field'(V, F) when erlang:is_map(V) -> maps:get(F, V);
'__bp_field'(V, F) -> erlang:apply(erlang:element(1, V), '__bp_get', [V, F]).

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
    persistent_term:erase({bp_load_cases_context_provide_made_in_body@main, themeContext}),
    themeContext(),
    ok.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '_botopink_init'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__Label'() -> 'Label'().

'__bp_priv__Dark'() -> 'Dark'().

'__bp_priv__Again'() -> 'Again'().
