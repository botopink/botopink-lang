-module(bp_load_cases_use_conditional_argument@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, themeContext/0, '__bp_priv__Label'/0, '__bp_priv__App'/1]).

%% import Context

%% import bpScopePush__, bpScopeFind__, bpScopeRendered__, bpScopeValue__, bpScopeRoot__

%%% Decision 357 (2) — once declared, always fed: a condition goes inside a

%%% `use`'s argument, never around the `use`. `use

%%% provide(createContext(if (dark) … else …))` is at the top level of the body and runs on every call;

%%% an `if` that does not return before a `use` leaves it at the top level

%%% too.

%% import RenderScope, createContext, provide, context

%% type Theme: mode

%% type Element: text

themeContext() ->
    case persistent_term:get({bp_load_cases_use_conditional_argument@main, themeContext}, '__bp_unset') of
        '__bp_unset' -> __BpV = {bp_load_cases_use_conditional_argument@main@@Theme, <<"default">>}, persistent_term:put({bp_load_cases_use_conditional_argument@main, themeContext}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'Label'() ->
    fun(BpScope__) ->
        T = std@context:find(BpScope__, <<"Theme">>, themeContext()),
        std@context:rendered({bp_load_cases_use_conditional_argument@main@@Element, erlang:element(2, T)}, BpScope__)
    end.

'App'(Dark) ->
    fun(BpScope__) ->
        Note = <<"">>,
        Note@2 = case Dark of
            true ->
                Note@1 = <<"!">>,
                Note@1;
            _ ->
                Note
        end,
        BpScopeKids__0 = std@context:push(BpScope__, <<"Theme">>, case Dark of
            true ->
                {bp_load_cases_use_conditional_argument@main@@Theme, <<"dark">>};
            false ->
                {bp_load_cases_use_conditional_argument@main@@Theme, <<"light">>}
        end),
        L = std@context:valueOf(('Label'())(BpScopeKids__0)),
        std@context:rendered({bp_load_cases_use_conditional_argument@main@@Element, <<('__bp_text'(erlang:element(2, L)))/binary, Note@2/binary>>}, BpScopeKids__0)
    end.

%% @Async — eager lowering
main() ->
    A = '__bp_field'((('App'(true))(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, A)]),
    B = '__bp_field'((('App'(false))(std@context@@RenderScope:root())), value),
    '__bp_print'([erlang:element(2, B)]).

%% @Async — eager lowering
'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

%% @Async — eager lowering
'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/use_conditional_argument|*">>.

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
    persistent_term:erase({bp_load_cases_use_conditional_argument@main, themeContext}),
    themeContext(),
    ok.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '_botopink_init'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__Label'() -> 'Label'().

'__bp_priv__App'(A0) -> 'App'(A0).
