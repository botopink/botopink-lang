-module(bp_load_cases_contract_block_method_on_array_wasm@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, 'ArrayDescribe_describe'/1, 'NumDescribe_describe'/1]).

%%% Decision 799, 872 — inside an extension block's method over `array<T>`, `self.join`, `self.length` and `self.toString()` resolve on every target.

%% behavior Describe

%% implement Describe for array

'ArrayDescribe_describe'(Self) ->
    <<('__bp_text'('__bp_prim_join'(Self, <<",">>)))/binary, "/", ('__bp_text'('__bp_prim_toString'('__bp_len'(Self, length))))/binary>>.

%% implement Describe for i32

'NumDescribe_describe'(Self) ->
    <<('__bp_text'('__bp_prim_toString'(Self)))/binary, "?">>.

main() ->
    Xs = [<<"a">>, <<"b">>, <<"c">>],
    '__bp_print'(['ArrayDescribe_describe'(Xs)]),
    N = 5,
    '__bp_print'(['NumDescribe_describe'(N)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/contract_block_method_on_array_wasm|*">>.

'__bp_prim_join'(Recv, Arg0) when erlang:is_list(Recv) ->
    iolist_to_binary(lists:join(Arg0, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Recv)));
'__bp_prim_join'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"join">>, 1, Recv}).

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

'__bp_len'(X, _) when erlang:is_list(X) -> erlang:length(X);
'__bp_len'(X, _) when erlang:is_binary(X) -> erlang:length(unicode:characters_to_list(X));
'__bp_len'(X, Field) -> maps:get(Field, X).

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
