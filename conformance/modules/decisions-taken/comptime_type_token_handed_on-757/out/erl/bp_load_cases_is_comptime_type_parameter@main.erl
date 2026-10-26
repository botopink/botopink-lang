-module(bp_load_cases_is_comptime_type_parameter@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__holds__Users'/1, '__bp_priv__holds__Orders'/1]).

%%% Decisions 667, 757 — a type to test against travels as a `comptime t:

%%% type<T>` parameter: the call `r.count(Users)` infers `T` from `t`, and the

%%% copy of `count` it compiles to (decision 417) tests `e is Users`, an

%%% ordinary run-time test with one answer on every target. A function of the

%%% module takes one the same way.

%% type Users: count

%% type Orders: total

%% type Registry: entries

holds__Users(V) ->
    ((erlang:is_tuple(V) andalso (erlang:tuple_size(V) =:= 2)) andalso (erlang:element(1, V) =:= bp_load_cases_is_comptime_type_parameter@main@@Users)).

holds__Orders(V) ->
    ((erlang:is_tuple(V) andalso (erlang:tuple_size(V) =:= 2)) andalso (erlang:element(1, V) =:= bp_load_cases_is_comptime_type_parameter@main@@Orders)).

main() ->
    Order = {bp_load_cases_is_comptime_type_parameter@main@@Orders, 9},
    User = {bp_load_cases_is_comptime_type_parameter@main@@Users, 2},
    R = {bp_load_cases_is_comptime_type_parameter@main@@Registry, [Order, User, User]},
    '__bp_print'([bp_load_cases_is_comptime_type_parameter@main@@Registry:count__Users(R)]),
    '__bp_print'([bp_load_cases_is_comptime_type_parameter@main@@Registry:count__Orders(R)]),
    '__bp_print'([holds__Users(Order)]),
    '__bp_print'([holds__Orders(Order)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/is_comptime_type_parameter|*">>.

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

'__bp_priv__holds__Users'(A0) -> holds__Users(A0).

'__bp_priv__holds__Orders'(A0) -> holds__Orders(A0).
