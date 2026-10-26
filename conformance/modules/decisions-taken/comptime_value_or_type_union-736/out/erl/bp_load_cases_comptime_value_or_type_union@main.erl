-module(bp_load_cases_comptime_value_or_type_union@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__atomKey'/1, '__bp_priv____bp_atomKey__type'/0, '__bp_priv__atomState'/2, '__bp_priv____bp_atomState__type'/1, '__bp_priv__currentUser'/0]).

%%% Decision 736 — a `comptime` parameter takes a value or a type:

%%% `comptime source: Atom<T> | type<T>`, the body testing `source is type<T>`.

%%% One function, one name, two forms: an `Atom<T>` value (`T` inferred from

%%% it, or written) or a type naming its implicit atom (`T` bound to the type).

%% type Atom: key, initial

%% type User: name

atomKey(Source) ->
    erlang:element(2, Source).

'__bp_atomKey__type'() ->
    <<"implicit">>.

atomState(Source, Fallback) ->
    erlang:element(3, Source).

'__bp_atomState__type'(Fallback) ->
    Fallback.

currentUser() ->
    case persistent_term:get({bp_load_cases_comptime_value_or_type_union@main, currentUser}, '__bp_unset') of
        '__bp_unset' -> __BpV = {bp_load_cases_comptime_value_or_type_union@main@@Atom, <<"currentUser">>, {bp_load_cases_comptime_value_or_type_union@main@@User, <<"ana">>}}, persistent_term:put({bp_load_cases_comptime_value_or_type_union@main, currentUser}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

main() ->
    '__bp_print'([atomKey(currentUser())]),
    '__bp_print'(['__bp_atomKey__type'()]),
    '__bp_print'([atomKey(currentUser())]),
    A = atomState(currentUser(), {bp_load_cases_comptime_value_or_type_union@main@@User, <<"none">>}),
    B = '__bp_atomState__type'({bp_load_cases_comptime_value_or_type_union@main@@User, <<"bo">>}),
    N = '__bp_atomState__type'(7),
    '__bp_print'([erlang:element(2, A)]),
    '__bp_print'([erlang:element(2, B)]),
    '__bp_print'([N]).

'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/comptime_value_or_type_union|*">>.

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
    persistent_term:erase({bp_load_cases_comptime_value_or_type_union@main, currentUser}),
    currentUser(),
    ok.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '_botopink_init'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__atomKey'(A0) -> atomKey(A0).

'__bp_priv____bp_atomKey__type'() -> '__bp_atomKey__type'().

'__bp_priv__atomState'(A0, A1) -> atomState(A0, A1).

'__bp_priv____bp_atomState__type'(A0) -> '__bp_atomState__type'(A0).

'__bp_priv__currentUser'() -> currentUser().
