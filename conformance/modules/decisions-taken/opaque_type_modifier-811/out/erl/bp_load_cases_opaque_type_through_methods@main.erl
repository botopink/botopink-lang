-module(bp_load_cases_opaque_type_through_methods@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__twice'/1, '__bp_priv__describe'/1]).

%%% Decisions 811 (1), 814 — an opaque type is built and opened only inside its own methods:

%%% outside, a `Token` is made by `Token.of`, read through its `pub` methods, passed, stored,

%%% compared with `==` and tested with `is`; its methods without `pub` are called anywhere in

%%% its module.

%% type Token: value, uses

% Decision 814 (2) — a method without `pub` is called anywhere in its module.

twice(T) ->
    bp_load_cases_opaque_type_through_methods@main@@Token:bumped(bp_load_cases_opaque_type_through_methods@main@@Token:bumped(T)).

describe(T) ->
    <<('__bp_text'(bp_load_cases_opaque_type_through_methods@main@@Token:value(T)))/binary, "\x{C3}\x{97}", ('__bp_text'(erlang:integer_to_binary(bp_load_cases_opaque_type_through_methods@main@@Token:uses(T))))/binary>>.

main() ->
    A = bp_load_cases_opaque_type_through_methods@main@@Token:'of'(<<"a">>),
    B = bp_load_cases_opaque_type_through_methods@main@@Token:used(bp_load_cases_opaque_type_through_methods@main@@Token:used(A)),
    '__bp_print'([describe(B)]),
    '__bp_print'([describe(twice(A))]),
    Kept = [A, B],
    '__bp_print'([erlang:length(Kept)]),
    '__bp_print'([(A =:= bp_load_cases_opaque_type_through_methods@main@@Token:'of'(<<"a">>))]),
    '__bp_print'([(A =:= B)]),
    X = B,
    '__bp_print'([((erlang:is_tuple(X) andalso (erlang:tuple_size(X) =:= 3)) andalso (erlang:element(1, X) =:= bp_load_cases_opaque_type_through_methods@main@@Token))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/opaque_type_through_methods|*">>.

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

'__bp_priv__twice'(A0) -> twice(A0).

'__bp_priv__describe'(A0) -> describe(A0).
