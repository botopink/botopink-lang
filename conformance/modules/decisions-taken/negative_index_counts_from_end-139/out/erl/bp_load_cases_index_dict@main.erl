-module(bp_load_cases_index_dict@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decision 63 (amended 2026-09-19) — an index is a method call: `d["k"]`

%%% **is** `d.at("k")` through the ambient `Index<K, V>` behavior that

%%% `Dict<K, V>` answers on its declaration, and the value of the expression is

%%% whatever `at` answers — `?V`. Three rules, one probe each:

%%% 

%%%   1. a present key answers the value — `d["a"]` is `1`;

%%%   2. an absent key is `null` (decision 47's one spelling of absent), and it

%%%      is an ANSWER, not a failure: the index has no typing rule of its own,

%%%      so it cannot be stricter than the method it is;

%%%   3. a `Dict<string, ?i32>` indexes to an optional too — `o["missing"]` is

%%%      `null` for the same reason its present values would be.

%%% 

%%% Decision 46 dissolves into this: the route to `Dict.at` IS the call, and

%%% there is one exit point for absent instead of one per backend.

%%% 

%%% Both halves have landed — `libs/std` at `e065b564` (the behaviors, `Dict`'s

%%% `lookup` → `at`) and the checker's rewrite (C-02) — and the PRESENT key

%%% answers `1` on all four backends. An empty optional prints `null` on all

%%% four too: erlang and beam write the atom `undefined` as `null`, and wasm

%%% boxes a `?V` over a type parameter (C-18's wasm half) — unboxed, the absent

%%% key printed `0`.

%% import Dict

main() ->
    D = std@collections@@Dict:insert(std@collections@@Dict:empty(), <<"a">>, 1),
    '__bp_print'([std@collections@@Dict:at(D, <<"a">>)]),
    O = std@collections@@Dict:empty(),
    '__bp_print'([std@collections@@Dict:at(O, <<"missing">>)]),
    '__bp_print'([std@collections@@Dict:at(D, <<"zz">>)]),
    '__bp_print'([<<"after">>]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/index_dict|*">>.

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
