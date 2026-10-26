-module(bp_load_cases_wat_prelude_representation_only@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__array_unique'/1, '__bp_priv__array_slice'/3]).

%% behavior array

array_range(Start, Stop) ->
    case ((Stop - Start) =< 0) of
        true ->
            [];
        false ->
            case ((Stop - Start) =:= 1) of
                true ->
                    [Start];
                false ->
                    Count = (Stop - Start),
                    Low = array_range(Start, (Start + (Count div 2))),
                    High = array_range((Start + (Count div 2)), Stop),
                    '__bp_prim_append'(Low, High)
            end
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Half = array_repeat(Value, (Times div 2)),
            case ((Times rem 2) =:= 0) of
                true ->
                    '__bp_prim_append'(Half, Half);
                false ->
                    '__bp_prim_append'('__bp_prim_append'(Half, Half), [Value])
            end
    end.

%%% Decision 442 — `wat_prelude` keeps only what defines a value's representation or talks to the host; everything that only computes over values is Zig, transpiled as std-wasm is (440).

%% import random

main() ->
    Text = <<"  Mixed Case, words  ">>,
    '__bp_print'([string:uppercase(string:trim(Text))]),
    '__bp_print'([(fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(string:trim(Text), <<", ">>)]),
    '__bp_print'([iolist_to_binary(string:replace(<<"a-b-c">>, <<"-">>, <<"+">>))]),
    '__bp_print'([(fun(__S, __L, __P) -> __N = max(__L - byte_size(__S), 0), __PadBin = case __P of <<>> -> <<>>; _ -> list_to_binary(lists:duplicate(__N, binary:first(__P))) end, <<__PadBin/binary, __S/binary>> end)(<<"7">>, 3, <<"0">>)]),
    '__bp_print'([(fun(__S, __Sub) -> __L = byte_size(__S), __SL = byte_size(__Sub), __Find = fun __F(__I) -> case __I < 0 of true -> -1; false -> case binary:part(__S, __I, min(__SL, __L - __I)) =:= __Sub of true -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __I))); false -> __F(__I - 1) end end end, __Find(__L - __SL) end)(<<"abcabc">>, <<"b">>)]),
    '__bp_print'([float_to_binary(1.5, [short])]),
    '__bp_print'([erlang:integer_to_binary(('__bp_int'((1 + 2147483647), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/main.bp:14:15">>)))]),
    '__bp_print'([1.0e21]),
    Xs = [3, 1, 3, 2],
    '__bp_print'([lists:reverse(Xs)]),
    '__bp_print'([array_unique(Xs)]),
    '__bp_print'([array_slice(Xs, 1, 3)]),
    '__bp_print'([iolist_to_binary(lists:join(<<"|">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(X) ->
        erlang:integer_to_binary(X)
    end, Xs))))]),
    std@io@random:seed(42),
    First = std@io@random:seededFloat(),
    std@io@random:seed(42),
    '__bp_print'([(First =:= std@io@random:seededFloat())]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/wat_prelude_representation_only|*">>.

array_unique(Self) ->
    Out = lists:foldl(fun(X, Out) ->
        case (not '__bp_prim_any'(Out, fun(Y) ->
            (Y =:= X)
        end)) of
            true -> '__bp_prim_append'(Out, [X]);
            _ -> Out
        end
    end, [], Self),
    Out.

array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

'__bp_prim_any'(Recv, Arg0) when erlang:is_list(Recv) ->
    array_any(Recv, Arg0);
'__bp_prim_any'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"any">>, 1, Recv}).

array_any(Self, Pred) ->
    (erlang:length(lists:filter(Pred, Self)) =/= 0).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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
    '__bp_load_siblings'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_load_siblings'() ->
    case code:which(?MODULE) of
        Path when erlang:is_list(Path) ->
            lists:foreach(fun(Src) ->
                case code:ensure_loaded(erlang:list_to_atom(filename:basename(Src, ".erl"))) of
                    {module, _} -> ok;
                    _ ->
                        case compile:file(Src, [binary, return_errors]) of
                            {ok, Mod, Bin} -> code:load_binary(Mod, Src, Bin);
                            Bad ->
                                io:format(standard_error, "error: ~ts does not compile - refusing to run~n  ~p~n", [Src, Bad]),
                                erlang:halt(1)
                        end
                end
            end, filelib:wildcard(filename:join(filename:dirname(Path), "*.erl")));
        _ -> ok
    end.

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__array_unique'(A0) -> array_unique(A0).

'__bp_priv__array_slice'(A0, A1, A2) -> array_slice(A0, A1, A2).
