-module(bp_load_cases_component_alias_answers_value@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, sheetContext/0, '__bp_priv__styledView'/1, '__bp_priv__badge'/1, '__bp_priv__Render'/1, '__bp_priv__Outer'/0]).

%% import Context

%% import bpScopePush__, bpScopeFind__, bpScopeRendered__, bpScopeValue__, bpScopeRoot__

%%% Decisions 388 and 118 — a function typed by an alias of `Component`

%%% (`-> StyledView`) is no component body: the alias types it and activates

%%% nothing, so it answers the lambda another body made (`styledView`'s), not

%%% a lambda of its own. `Render` `use`s what a function value typed by the

%%% alias answers below its provider, so `styledView` reads `Render`'s sheet;

%%% `Outer` `use`s `badge("blue")` in its own body, run with `Outer`'s

%%% children scope (decision 791 (3)).

%% import RenderScope, createContext, provide, context

%% type Styled: className

%% type Sheet: name

sheetContext() ->
    case persistent_term:get({bp_load_cases_component_alias_answers_value@main, sheetContext}, '__bp_unset') of
        '__bp_unset' -> __BpV = {bp_load_cases_component_alias_answers_value@main@@Sheet, <<"default">>}, persistent_term:put({bp_load_cases_component_alias_answers_value@main, sheetContext}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

styledView(C) ->
    fun(BpScope__) ->
        S = std@context:find(BpScope__, <<"Sheet">>, sheetContext()),
        std@context:rendered({bp_load_cases_component_alias_answers_value@main@@Styled, <<C/binary, "@", ('__bp_text'(erlang:element(2, S)))/binary>>}, BpScope__)
    end.

badge(C) ->
    styledView(C).

'Render'(View) ->
    fun(BpScope__) ->
        BpScopeKids__0 = std@context:push(BpScope__, <<"Sheet">>, {bp_load_cases_component_alias_answers_value@main@@Sheet, <<"render">>}),
        Out = std@context:valueOf((View())(BpScopeKids__0)),
        std@context:rendered(Out, BpScopeKids__0)
    end.

'Outer'() ->
    fun(BpScope__) ->
        BpScopeKids__1 = std@context:push(BpScope__, <<"Sheet">>, {bp_load_cases_component_alias_answers_value@main@@Sheet, <<"outer">>}),
        B = std@context:valueOf((badge(<<"blue">>))(BpScopeKids__1)),
        std@context:rendered(B, BpScopeKids__1)
    end.

%% @Async — eager lowering
main() ->
    R = '__bp_field'((('Render'(fun() ->
        badge(<<"red">>)
    end))(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, R)]),
    O = '__bp_field'((('Outer'())(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, O)]).

%% @Async — eager lowering
'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

%% @Async — eager lowering
'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/component_alias_answers_value|*">>.

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
    persistent_term:erase({bp_load_cases_component_alias_answers_value@main, sheetContext}),
    sheetContext(),
    ok.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '_botopink_init'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__styledView'(A0) -> styledView(A0).

'__bp_priv__badge'(A0) -> badge(A0).

'__bp_priv__Render'(A0) -> 'Render'(A0).

'__bp_priv__Outer'() -> 'Outer'().
