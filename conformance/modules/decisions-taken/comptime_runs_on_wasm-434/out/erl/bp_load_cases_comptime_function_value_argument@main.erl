-module(bp_load_cases_comptime_function_value_argument@main).
-compile({no_auto_import,[apply/2]}).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__half'/1, '__bp_priv__double'/1, '__bp_priv__apply'/2, '__bp_priv__measure'/1, '__bp_priv__summary'/1]).

%%% Decisions 331, 434 (5) — a function named as a value and passed as an

%%% argument (`r.flatMap(half)`, `xs.map(double)`, `apply(double, 4)`) runs at

%%% build as it does when the program runs, in a function a `comptime` reaches.

half(N) ->
    case ((N rem 2) =/= 0) of
        true ->
            {error, <<"odd">>};
        _ ->
            {ok, '__bp_int'((N div 2), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/main.bp:9:14">>)}
    end.

double(N) ->
    '__bp_int'((N * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:13:14">>).

apply(F, N) ->
    F(N).

measure(Text) ->
    case (Text =:= <<"nope">>) of
        true ->
            {error, <<"no text">>};
        _ ->
            {ok, erlang:length(unicode:characters_to_list(Text))}
    end.

summary(Text) ->
    Halved = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> ((-1)) end end)((fun(__BpR) -> case __BpR of {ok, __BpV1} -> (fun half/1)(__BpV1); _ -> __BpR end end)(measure(Text))),
    Doubled = (fun(__BpR) -> case __BpR of {ok, __BpV2} -> __BpV2; _ -> (0) end end)((fun(__BpR) -> case __BpR of {ok, __BpV3} -> {ok, (fun double/1)(__BpV3)}; _ -> __BpR end end)(measure(Text))),
    Listed = lists:map(fun double/1, [1, 2, 3]),
    <<('__bp_text'(erlang:integer_to_binary(Halved)))/binary, " ", ('__bp_text'(erlang:integer_to_binary(Doubled)))/binary, " ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Listed)))))/binary, " ", ('__bp_text'(erlang:integer_to_binary(apply(fun double/1, 4))))/binary>>.

main() ->
    A = <<"2 8 2,4,6 8">>,
    '__bp_print'([A]),
    '__bp_print'([(A =:= summary(<<"abcd">>))]),
    B = <<"-1 6 2,4,6 8">>,
    '__bp_print'([B]),
    '__bp_print'([(B =:= summary(<<"abc">>))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/comptime_function_value_argument|*">>.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__half'(A0) -> half(A0).

'__bp_priv__double'(A0) -> double(A0).

'__bp_priv__apply'(A0, A1) -> apply(A0, A1).

'__bp_priv__measure'(A0) -> measure(A0).

'__bp_priv__summary'(A0) -> summary(A0).
