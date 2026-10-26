-module(bp_load_cases_import_std_type_through_module@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decisions 110 and 111 — a `collections` constructor is type-scoped, and

%%% the module namespace reaches the type: `collections.Dict.empty()` after

%%% `import {collections} from "std"` is the leaf form's `Dict.empty()`,

%%% beside the module's own functions (`collections.lt()`) and an alias of

%%% the same type (`D`).

%% import collections, Dict, Set, Queue

%% import Dict

main() ->
    D = std@collections@@Dict:insert(std@collections@@Dict:insert(std@collections@@Dict:empty(), <<"k">>, 7), <<"j">>, 1),
    '__bp_print'([std@collections@@Dict:size(D)]),
    '__bp_print'([case std@collections@@Dict:at(D, <<"k">>) of
        undefined ->
            0;
        __bp_nullish ->
            __bp_nullish
    end]),
    S = std@collections@@Set:fromList([1, 2, 2, 3]),
    '__bp_print'([std@collections@@Set:size(S)]),
    Q = std@collections@@Queue:enqueue(std@collections@@Queue:fromList([<<"a">>, <<"b">>]), <<"c">>),
    '__bp_print'([std@collections@@Queue:size(Q)]),
    '__bp_print'([std@collections:toInt(std@collections:lt())]),
    E = std@collections@@Dict:empty(),
    '__bp_print'([std@collections@@Dict:size(E)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/import_std_type_through_module|*">>.

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
