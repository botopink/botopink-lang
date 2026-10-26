-module(bp_load_cases_record_param_on_method@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decision 864 (5) — a method takes a record parameter as a function does:

%%% the labels name `R`'s fields and the method's other parameters, a spread

%%% is packed into one `R(…)` at the call, and a positional argument counts

%%% the other parameters only (`self` is not one).

%% type CardProps: title, featured, size

%% type Shelf: name

main() ->
    S = {bp_load_cases_record_param_on_method@main@@Shelf, <<"s">>},
    '__bp_print'([bp_load_cases_record_param_on_method@main@@Shelf:add(S, {bp_load_cases_record_param_on_method@main@@CardProps, <<"a">>, false, 1}, <<"!">>)]),
    '__bp_print'([bp_load_cases_record_param_on_method@main@@Shelf:add(S, {bp_load_cases_record_param_on_method@main@@CardProps, <<"b">>, true, 3}, <<"?">>)]),
    Base = {bp_load_cases_record_param_on_method@main@@CardProps, <<"c">>, false, 7},
    '__bp_print'([bp_load_cases_record_param_on_method@main@@Shelf:add(S, {bp_load_cases_record_param_on_method@main@@CardProps, erlang:element(2, Base), erlang:element(3, Base), erlang:element(4, Base)}, <<".">>)]),
    '__bp_print'([bp_load_cases_record_param_on_method@main@@Shelf:add(S, {bp_load_cases_record_param_on_method@main@@CardProps, <<"d">>, false, 1}, <<"#">>)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/record_param_on_method|*">>.

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
