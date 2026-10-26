-module(bp_load_cases_contract_block_method_on_int@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, 'IntShout_label'/1, shout/1, 'TextShout_label'/1, '__bp_priv__string_shout'/1]).

%% behavior string

%%% Decision 799, 872 — an extension block's own method on an `i32` receiver answers on every target.

%% behavior Shout

%% implement Shout for i32

'IntShout_label'(Self) ->
    <<"n:", ('__bp_text'('__bp_prim_toString'(Self)))/binary>>.

shout(Self) ->
    <<('__bp_text'('IntShout_label'(Self)))/binary, "!">>.

%% implement Shout for string

'TextShout_label'(Self) ->
    <<"t:", ('__bp_text'(Self))/binary>>.

main() ->
    N = 7,
    '__bp_print'(['IntShout_label'(N)]),
    '__bp_print'([shout(N)]),
    '__bp_print'([erlang:integer_to_binary(erlang:length(unicode:characters_to_list(shout(N))))]),
    '__bp_print'(['TextShout_label'(<<"x">>)]),
    '__bp_print'([string_shout(<<"x">>)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/contract_block_method_on_int|*">>.

string_shout(Self) ->
    <<('__bp_text'('TextShout_label'(Self)))/binary, "!">>.

'__bp_prim_toString'(Recv) when erlang:is_binary(Recv) ->
    string_toString(Recv);
'__bp_prim_toString'(Recv) when erlang:is_boolean(Recv) ->
    erlang:atom_to_binary(Recv);
'__bp_prim_toString'(Recv) when erlang:is_integer(Recv) ->
    erlang:integer_to_binary(Recv);
'__bp_prim_toString'(Recv) when erlang:is_float(Recv) ->
    float_to_binary(Recv, [short]);
'__bp_prim_toString'(Recv) ->
    '__bp_text'(Recv).

string_toString(Self) ->
    Self.

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

'__bp_priv__string_shout'(A0) -> string_shout(A0).
