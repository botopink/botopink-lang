-module(bp_load_cases_optional_chain_absent_array_length@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decision 330 — `?.` along a chain ending in a method of an optional array

%%% field: `h?.fields?.length()` is absent when `h` is absent and when `fields`

%%% is, so `?? 0` answers `0`, on every target.

%% type Field: name

%% type Form: fields

main() ->
    '__bp_print'([<<"start">>]),
    H = undefined,
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain0) -> erlang:length(Bp__chain0) end)((fun(undefined) -> undefined; (_Opt1) -> erlang:element(2, _Opt1) end)(H)) of
        undefined ->
            0;
        __bp_nullish ->
            __bp_nullish
    end]),
    N = (fun(undefined) -> undefined; (Bp__chain2) -> erlang:length(Bp__chain2) end)((fun(undefined) -> undefined; (_Opt3) -> erlang:element(2, _Opt3) end)(H)),
    '__bp_print'([case N of
        undefined ->
            0;
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    E = {bp_load_cases_optional_chain_absent_array_length@main@@Form, undefined},
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain4) -> erlang:length(Bp__chain4) end)((fun(undefined) -> undefined; (_Opt5) -> erlang:element(2, _Opt5) end)(E)) of
        undefined ->
            0;
        __bp_nullish@2 ->
            __bp_nullish@2
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_chain_absent_array_length|*">>.

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
