-module(bp_load_cases_ambient_behavior_parameter@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__shut'/1, '__bp_priv__show'/1]).

%%% Decision 539 (6) — `Closeable` and `Display` are ambient behaviors of `primitives.bp`: a

%%% program names them as a parameter's type with no import, and a call on such a value

%%% dispatches to the implementer's method.

%% type Door: name

%% type Money: cents

shut(C) ->
    '__bp_method'(close, C, []).

show(D) ->
    '__bp_method'(display, D, []).

main() ->
    shut({bp_load_cases_ambient_behavior_parameter@main@@Door, <<"front">>}),
    Doors = [{bp_load_cases_ambient_behavior_parameter@main@@Door, <<"back">>}, {bp_load_cases_ambient_behavior_parameter@main@@Door, <<"side">>}],
    lists:foreach(fun(D) ->
        shut(D)
    end, Doors),
    '__bp_print'([show({bp_load_cases_ambient_behavior_parameter@main@@Money, 7})]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/ambient_behavior_parameter|*">>.

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

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__shut'(A0) -> shut(A0).

'__bp_priv__show'(A0) -> show(A0).
