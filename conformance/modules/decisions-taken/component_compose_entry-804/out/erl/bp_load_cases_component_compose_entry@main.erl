-module(bp_load_cases_component_compose_entry@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, themeContext/0, '__bp_priv__Card'/2, '__bp_priv__Page'/0]).

%% import Context

%% import bpScopePush__, bpScopeFind__, bpScopeRendered__, bpScopeValue__, bpScopeRoot__

%%% Decision 804 (1) — a type implementing `Component<R>` is a component: its

%%% fields are the props, `fn compose(self: Self) -> Component<R>` is where it

%%% starts, and `Card(…)` answers the component, never a record. `Page`

%%% provides `dark`, so the `Card` it `use`s reads `dark` and calls its helper

%%% `label`; the `Card` it only calls makes a lambda that nothing runs, so

%%% `compose ran` prints twice: once under `Page`, once at the root.

%% import createContext, provide, context, RenderScope

%% type Theme: mode

%% type View: text

themeContext() ->
    case persistent_term:get({bp_load_cases_component_compose_entry@main, themeContext}, '__bp_unset') of
        '__bp_unset' -> __BpV = {bp_load_cases_component_compose_entry@main@@Theme, <<"light">>}, persistent_term:put({bp_load_cases_component_compose_entry@main, themeContext}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

%% type Card__Self: title, body

'Card'(Title, Body) ->
    fun(BpScope__) ->
        Compose__self = {bp_load_cases_component_compose_entry@main@@Card__Self, Title, Body},
        T = std@context:find(BpScope__, <<"Theme">>, themeContext()),
        '__bp_print'([<<"compose ran">>]),
        std@context:rendered({bp_load_cases_component_compose_entry@main@@View, <<('__bp_text'(erlang:element(2, T)))/binary, ":", ('__bp_text'(erlang:element(2, Compose__self)))/binary, "/", ('__bp_text'(bp_load_cases_component_compose_entry@main@@Card__Self:label(Compose__self)))/binary>>}, BpScope__)
    end.

'Page'() ->
    fun(BpScope__) ->
        BpScopeKids__0 = std@context:push(BpScope__, <<"Theme">>, {bp_load_cases_component_compose_entry@main@@Theme, <<"dark">>}),
        Made = 'Card'(<<"lazy">>, <<"none">>),
        C = std@context:valueOf(('Card'(<<"used">>, <<"b">>))(BpScopeKids__0)),
        std@context:rendered({bp_load_cases_component_compose_entry@main@@View, <<"page ", ('__bp_text'(erlang:element(2, C)))/binary>>}, BpScopeKids__0)
    end.

%% @Async — eager lowering
main() ->
    R = ('Page'())(std@context@@RenderScope:root()),
    '__bp_print'([erlang:element(2, '__bp_field'(R, value))]),
    Alone = ('Card'(<<"root">>, <<"none">>))(std@context@@RenderScope:root()),
    '__bp_print'([erlang:element(2, '__bp_field'(Alone, value))]).

%% @Async — eager lowering
'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

%% @Async — eager lowering
'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/component_compose_entry|*">>.

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
    persistent_term:erase({bp_load_cases_component_compose_entry@main, themeContext}),
    themeContext(),
    ok.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '_botopink_init'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__Card'(A0, A1) -> 'Card'(A0, A1).

'__bp_priv__Page'() -> 'Page'().
