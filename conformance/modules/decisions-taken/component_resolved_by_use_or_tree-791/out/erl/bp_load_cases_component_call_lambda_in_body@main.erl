-module(bp_load_cases_component_call_lambda_in_body@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__mk'/1, '__bp_priv__Sheet'/0]).

%% import bpScopePush__, bpScopeFind__, bpScopeRendered__, bpScopeValue__, bpScopeRoot__

%%% Decision 791 (1) — a call of a component only makes its lambda, in a

%%% component body too: `mk(2)` in `Sheet`, a body written

%%% `-> Component<string>`, answers `Component<Prop>`, so it binds to a `val`

%%% written with that type and sits in a list of them; nothing runs (`ran`

%%% never prints). The root is run by `Sheet().run(RenderScope.root())`.

%% import RenderScope

%% type Prop: d

mk(N) ->
    fun(BpScope__) ->
        '__bp_print'([<<"ran ", ('__bp_text'(erlang:integer_to_binary(N)))/binary>>]),
        std@context:rendered({bp_load_cases_component_call_lambda_in_body@main@@Prop, erlang:integer_to_binary(N)}, BpScope__)
    end.

'Sheet'() ->
    fun(BpScope__) ->
        X = mk(2),
        Xs = [X, mk(3)],
        std@context:rendered(<<"made ", ('__bp_text'(erlang:integer_to_binary(erlang:length(Xs))))/binary>>, BpScope__)
    end.

%% @Async — eager lowering
main() ->
    R = ('Sheet'())(std@context@@RenderScope:root()),
    '__bp_print'(['__bp_field'(R, value)]).

%% @Async — eager lowering
'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

%% @Async — eager lowering
'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/component_call_lambda_in_body|*">>.

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

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__mk'(A0) -> mk(A0).

'__bp_priv__Sheet'() -> 'Sheet'().
