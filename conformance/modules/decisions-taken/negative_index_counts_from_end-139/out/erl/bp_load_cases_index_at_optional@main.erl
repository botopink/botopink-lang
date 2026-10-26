-module(bp_load_cases_index_at_optional@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decision 63 (amended 2026-09-19), the `libs/std` half — `Dict.lookup` and

%%% `String.charAt` became `at`, the one reader name every indexable type has

%%% (`e065b564`, C-02's std half). Called by name, `at` is the feature decision

%%% 30 kept distinct from the index: it answers `?V`, and an absent key or index

%%% is `null` — decision 47's one spelling for absent.

%%% 

%%% The cell prints a present and an absent probe for each of the two renamed

%%% readers. `Array.at` past the end is deliberately not here: it answers

%%% `undefined` on commonJS at `85f883bd` (decision 47's row, the `array_at`

%%% helper on every backend — C-18), and it would hide this cell's claim behind

%%% that one.

%%% 

%%% Measured at `85f883bd` (2026-09-20):

%%% 

%%%   commonJS  `1`, `null`, `b`, `null` — correct

%%%   erlang    `1`, `undefined`, `b`, `undefined` — the absent optional prints

%%%             the atom, not `null` (decision 47, C-18)

%%%   wasm      `1`, `null`, `b`, `null` — correct: `Dict.at`'s `?V` over a

%%%             type parameter is boxed (C-18's wasm half; unboxed, the absent

%%%             key printed `0`), and `String.at` has its std-wasm's `text.at` lowering,

%%%             which `run/string_at.bp` pins on all four targets

%% import Dict

main() ->
    D = std@collections@@Dict:insert(std@collections@@Dict:empty(), <<"a">>, 1),
    '__bp_print'([std@collections@@Dict:at(D, <<"a">>)]),
    '__bp_print'([std@collections@@Dict:at(D, <<"zz">>)]),
    S = <<"abc">>,
    '__bp_print'([(fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(S, 1)]),
    '__bp_print'([(fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(S, 7)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/index_at_optional|*">>.

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
