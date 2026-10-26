-module(bp_load_cases_component_is_lambda@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, prefixContext/0, '__bp_priv__Card'/1, '__bp_priv__Lista'/1, '__bp_priv__twice'/1, '__bp_priv__render'/2]).

%% import Context

%% import bpScopePush__, bpScopeFind__, bpScopeRendered__, bpScopeValue__, bpScopeRoot__

%%% Decision 388 (1) — a component at run time is a lambda over a

%%% `RenderScope`: the call `Card(item)` runs nothing (`made` prints before

%%% any `ran`), so `itens.map(Card)` answers lambdas and generic code needs

%%% nothing of a component (`twice` keeps two of them). `Lista` places the

%%% lambdas in its tree, and the tree's runner (`render`) runs them with the

%%% scope `Lista`'s run answered — the one its `use provide` made — so every

%%% card reads `Lista`'s prefix, after `Lista`'s own body ended.

%% import createContext, provide, context, RenderScope

%% type Item: name

%% type View: text, kids

prefixContext() ->
    <<"">>.

'Card'(Item) ->
    fun(BpScope__) ->
        P = std@context:find(BpScope__, <<"string">>, prefixContext()),
        '__bp_print'([<<"ran ", ('__bp_text'(erlang:element(2, Item)))/binary>>]),
        std@context:rendered({bp_load_cases_component_is_lambda@main@@View, '__bp_add'(P, erlang:element(2, Item)), []}, BpScope__)
    end.

'Lista'(Itens) ->
    fun(BpScope__) ->
        BpScopeKids__0 = std@context:push(BpScope__, <<"string">>, <<"#">>),
        Cards = lists:map(fun 'Card'/1, Itens),
        '__bp_print'([<<"lista made ", ('__bp_text'(erlang:integer_to_binary(erlang:length(Cards))))/binary>>]),
        std@context:rendered({bp_load_cases_component_is_lambda@main@@View, <<"lista">>, Cards}, BpScopeKids__0)
    end.

twice(X) ->
    [X, X].

% Run `c` with `scope`, then each child with the scope `c`'s run answered.

%% @Async — eager lowering
render(C, Scope) ->
    R = (C)(Scope),
    Out = erlang:element(2, '__bp_field'(R, value)),
    Out@3 = '__bp_iter_foldl'(fun(K, Out@1) ->
        Inner = render(K, '__bp_field'(R, scope)),
        Out@2 = <<Out@1/binary, " ", ('__bp_text'(Inner))/binary>>,
        Out@2
    end, Out, erlang:element(3, '__bp_field'(R, value))),
    Out@3.

%% @Async — eager lowering
main() ->
    C = 'Card'({bp_load_cases_component_is_lambda@main@@Item, <<"x">>}),
    Cs = twice(C),
    '__bp_print'([<<"made ", ('__bp_text'(erlang:integer_to_binary(erlang:length(Cs))))/binary>>]),
    '__bp_print'([render('Lista'([{bp_load_cases_component_is_lambda@main@@Item, <<"a">>}, {bp_load_cases_component_is_lambda@main@@Item, <<"b">>}]), std@context@@RenderScope:root())]).

%% @Async — eager lowering
'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

%% @Async — eager lowering
'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/component_is_lambda|*">>.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

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

'__bp_iter_foldl'(__BpA0, __BpA1, __BpA2) ->
    case __BpA2 of
{'__bp_gen', P} ->
Dict = fun() -> lists:filter(fun({DK, _}) -> DK =/= '__bp_gen_self' andalso DK =/= '__bp_gen_mon' end, erlang:get()) end,
Load = fun(LD) ->
    LOwn = erlang:get('__bp_gen_self'),
    LMon = erlang:get('__bp_gen_mon'),
    erlang:erase(),
    lists:foreach(fun({LK, LV}) -> erlang:put(LK, LV) end, LD),
    case LOwn of undefined -> ok; _ -> erlang:put('__bp_gen_self', LOwn) end,
    case LMon of undefined -> ok; _ -> erlang:put('__bp_gen_mon', LMon) end
end,
Call = fun(CPid, CCmd) ->
    CM = erlang:monitor(process, CPid),
    erlang:send(CPid, {'__bp_gen', CCmd, erlang:self(), CM, Dict()}),
    receive
        {CM, item, CV, CD} -> erlang:demonitor(CM, [flush]), Load(CD), [CV];
        {CM, done, CD} -> erlang:demonitor(CM, [flush]), Load(CD), [];
        {CM, raise, CC, CR, CS, CD} -> erlang:demonitor(CM, [flush]), Load(CD), erlang:raise(CC, CR, CS);
        {'DOWN', CM, process, _, _} -> []
    end
end,
W = fun WF(A) -> case Call(P, next) of [V] -> WF(__BpA0(V, A)); [] -> A end end,
try W(__BpA1) catch WC:WR:WS -> Call(P, close), erlang:raise(WC, WR, WS) end;
L -> lists:foldl(__BpA0, __BpA1, L)
end.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__Card'(A0) -> 'Card'(A0).

'__bp_priv__Lista'(A0) -> 'Lista'(A0).

'__bp_priv__twice'(A0) -> twice(A0).

'__bp_priv__render'(A0, A1) -> render(A0, A1).
