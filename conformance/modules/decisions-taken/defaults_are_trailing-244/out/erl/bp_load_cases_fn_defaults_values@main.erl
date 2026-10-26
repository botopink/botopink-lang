-module(bp_load_cases_fn_defaults_values@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__connect'/2]).

%%% C-04 (01 step 7, N1) — the VALUE of an omitted trailing default, on every

%%% backend. `test/fn_defaults.bp` makes the same claim, but `botopink test`

%%% runs on commonJS and erlang only, and the whole defect was that the

%%% declared value never arrived: a cell that merely compiles proves nothing.

%%% 

%%% Each of the three shapes a default can be declared in appears once — a free

%%% `fn`, a record constructor and an instance method — and the last line is

%%% a constructor called by label: `P(y: 2)` names the required field and

%%% omits the defaulted one after it (a default is trailing, decision 244).

connect(Host, Port) ->
    <<Host/binary, ":", ('__bp_text'(erlang:integer_to_binary(Port)))/binary>>.

%% type P: y, x

main() ->
    '__bp_print'([connect(<<"h">>, 80)]),
    '__bp_print'([connect(<<"h">>, 90)]),
    P = {bp_load_cases_fn_defaults_values@main@@P, 2, 0},
    '__bp_print'([erlang:element(3, P)]),
    '__bp_print'([erlang:element(2, P)]),
    '__bp_print'([bp_load_cases_fn_defaults_values@main@@P:bump(P, 5)]),
    '__bp_print'([bp_load_cases_fn_defaults_values@main@@P:bump(P, 1)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/fn_defaults_values|*">>.

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

'__bp_priv__connect'(A0, A1) -> connect(A0, A1).
