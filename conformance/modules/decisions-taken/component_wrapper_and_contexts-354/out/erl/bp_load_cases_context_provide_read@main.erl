-module(bp_load_cases_context_provide_read@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, themeContext/0, '__bp_priv__themeName'/0, '__bp_priv__Label'/1, '__bp_priv__Page'/0, '__bp_priv__App'/0, '__bp_priv__Root'/0]).

%% import Context

%% import bpScopePush__, bpScopeFind__, bpScopeRendered__, bpScopeValue__, bpScopeRoot__

%%% Decision 354 (2), (8) — a context provided by a component reaches every

%%% component it renders below it, through the hidden context map every

%%% `Component` function takes: `App` provides `ThemeContext`, `Page` (a

%%% component `App` renders) renders `Label`, and `Label` reads the value.

%%% A `Component` read with `use` (`themeName`) reads the map its caller

%%% received. `App` itself does not see its own provide — `Root` provides the

%%% one `App` reads.

%% import RenderScope, createContext, provide, context

%% type Theme: mode

%% type Element: text

themeContext() ->
    case persistent_term:get({bp_load_cases_context_provide_read@main, themeContext}, '__bp_unset') of
        '__bp_unset' -> __BpV = {bp_load_cases_context_provide_read@main@@Theme, <<"default">>}, persistent_term:put({bp_load_cases_context_provide_read@main, themeContext}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

themeName() ->
    fun(BpScope__) ->
        T = std@context:find(BpScope__, <<"Theme">>, themeContext()),
        std@context:rendered(erlang:element(2, T), BpScope__)
    end.

'Label'(Prefix) ->
    fun(BpScope__) ->
        Name = std@context:valueOf((themeName())(BpScope__)),
        std@context:rendered({bp_load_cases_context_provide_read@main@@Element, <<Prefix/binary, ('__bp_text'(Name))/binary>>}, BpScope__)
    end.

'Page'() ->
    fun(BpScope__) ->
        L = std@context:valueOf(('Label'(<<"label:">>))(BpScope__)),
        std@context:rendered({bp_load_cases_context_provide_read@main@@Element, <<"page[", ('__bp_text'(erlang:element(2, L)))/binary, "]">>}, BpScope__)
    end.

'App'() ->
    fun(BpScope__) ->
        Outer = std@context:find(BpScope__, <<"Theme">>, themeContext()),
        BpScopeKids__0 = std@context:push(BpScope__, <<"Theme">>, {bp_load_cases_context_provide_read@main@@Theme, <<"dark">>}),
        P = std@context:valueOf(('Page'())(BpScopeKids__0)),
        std@context:rendered({bp_load_cases_context_provide_read@main@@Element, <<('__bp_text'(erlang:element(2, Outer)))/binary, " ", ('__bp_text'(erlang:element(2, P)))/binary>>}, BpScopeKids__0)
    end.

'Root'() ->
    fun(BpScope__) ->
        BpScopeKids__1 = std@context:push(BpScope__, <<"Theme">>, {bp_load_cases_context_provide_read@main@@Theme, <<"light">>}),
        A = std@context:valueOf(('App'())(BpScopeKids__1)),
        std@context:rendered({bp_load_cases_context_provide_read@main@@Element, erlang:element(2, A)}, BpScopeKids__1)
    end.

%% @Async — eager lowering
main() ->
    R = '__bp_field'((('Root'())(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, R)]).

%% @Async — eager lowering
'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

%% @Async — eager lowering
'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/context_provide_read|*">>.

'__bp_field'(V, F) when erlang:is_map(V) -> maps:get(F, V);
'__bp_field'(V, F) -> erlang:apply(erlang:element(1, V), '__bp_get', [V, F]).

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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
    persistent_term:erase({bp_load_cases_context_provide_read@main, themeContext}),
    themeContext(),
    ok.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '_botopink_init'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__themeName'() -> themeName().

'__bp_priv__Label'(A0) -> 'Label'(A0).

'__bp_priv__Page'() -> 'Page'().

'__bp_priv__App'() -> 'App'().

'__bp_priv__Root'() -> 'Root'().
