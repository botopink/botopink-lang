-module(bp_load_cases_record_update@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decision 37's update form: `Name(..base, field: value)` is a new record

%%% with the fields it names replaced and every other field read from `base`.

%%% The checker matched each label to its field, but no backend lowered the

%%% `..` argument: each dropped it and zipped what was left, so

%%% `Cfg(..base, revalidate: 60)` built `Cfg(base, 60)` — the base record in

%%% the first field and the third one missing, on all four targets.

%% type Cfg: a, revalidate, name

%% type Inner: v, w

%% type Outer: inner, n

%% type Box: value, tag

main() ->
    Base = {bp_load_cases_record_update@main@@Cfg, 1, 0, <<"x">>},
    C = {bp_load_cases_record_update@main@@Cfg, erlang:element(2, Base), 60, erlang:element(4, Base)},
    '__bp_print'([erlang:element(2, C)]),
    '__bp_print'([erlang:element(3, C)]),
    '__bp_print'([erlang:element(4, C)]),
    '__bp_print'([erlang:element(3, Base)]),
    O = {bp_load_cases_record_update@main@@Outer, {bp_load_cases_record_update@main@@Inner, 5, <<"q">>}, 2},
    I = {bp_load_cases_record_update@main@@Inner, erlang:element(2, erlang:element(2, O)), <<"z">>},
    '__bp_print'([erlang:element(2, I)]),
    '__bp_print'([erlang:element(3, I)]),
    Both = {bp_load_cases_record_update@main@@Inner, 9, <<"y">>},
    '__bp_print'([erlang:element(2, Both)]),
    '__bp_print'([erlang:element(3, Both)]),
    B = {bp_load_cases_record_update@main@@Box, 3, <<"t">>},
    B2 = {bp_load_cases_record_update@main@@Box, 4, erlang:element(3, B)},
    '__bp_print'([erlang:element(2, B2)]),
    '__bp_print'([erlang:element(3, B2)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/record_update|*">>.

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
