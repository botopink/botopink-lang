-module(bp_load_cases_std_async_on_every_target@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__slow'/2, '__bp_priv__gated'/2, '__bp_priv__handshake'/3, '__bp_priv__pauseText'/2, '__bp_priv__show'/2, '__bp_priv__run'/0]).

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

%%% 144 B-25 (`02/97` step 17; decisions 334, 335 (2), 392) — std's `async` on

%%% every target: `delay`, `all`, `allOf`, `race`, `runAll`, `raceOf`,

%%% `timeout`, the gates and `nextDelay` answer alike on commonJS, erlang, beam and

%%% wasm (under wasmtime and under node). The results and the order of the

%%% answers are the contract — `all`, `allOf` and `runAll` answer in input

%%% order, `raceOf` the first thunk to settle —, never the order of effects

%%% between concurrent tasks: every line is printed from one task chain.

%%% `race` over started tasks answers element zero on erlang (its tasks ran

%%% before the call), so its fastest task is element zero here.

%% import async, Gate, RetryPolicy

%% @Async — eager lowering
slow(Millis, Value) ->
    V = std@async:delay(Millis, Value),
    {ok, V}.

% `value` once `gate` opens, a value naming the failure when it never does.

%% @Async — eager lowering
gated(Gate, Value) ->
    Opened = std@async:awaitGate(Gate, 10000),
    case Opened of
        true ->
            Value;
        false ->
            <<"never opened: ", Value/binary>>
    end.

% Open `mine`, then answer `value` once `theirs` is open.

%% @Async — eager lowering
handshake(Mine, Theirs, Value) ->
    std@async:openGate(Mine),
    gated(Theirs, Value).

pauseText(Policy, Attempt) ->
    Pause = std@async:nextDelay(Policy, Attempt),
    case (Pause =/= undefined) of
        true ->
            erlang:integer_to_binary(Pause);
        false ->
            <<"none">>
    end.

show(Label, R) ->
    case R of
        {ok, Xs} ->
            '__bp_print'([<<Label/binary, " ok ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Xs)))))/binary>>]);
        {error, E} ->
            '__bp_print'([<<Label/binary, " error ", ('__bp_text'(E))/binary>>])
    end.

%% @Async — eager lowering
run() ->
    D = std@async:delay(5, <<"delayed">>),
    '__bp_print'([<<"delay ", ('__bp_text'(D))/binary>>]),
    All = std@async:all([std@async:delay(20, <<"a">>), std@async:delay(1, <<"b">>)]),
    '__bp_print'([<<"all ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, All)))))/binary>>]),
    show(<<"allOf">>, std@async:allOf([slow(20, <<"x">>), slow(1, <<"y">>)])),
    show(<<"allOf">>, std@async:allOf([slow(1, <<"x">>), std@async:failed(<<"down">>), std@async:failed(<<"later">>)])),
    First = std@async:race([std@async:delay(1, <<"first">>), std@async:delay(60, <<"second">>)]),
    '__bp_print'([<<"race ", ('__bp_text'(First))/binary>>]),
    Ran = std@async:runAll([fun() ->
        std@async:delay(20, <<"one">>)
    end, fun() ->
        std@async:delay(5, <<"two">>)
    end, fun() ->
        std@async:delay(1, <<"three">>)
    end]),
    '__bp_print'([<<"runAll ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Ran)))))/binary>>]),
    Won = std@async:raceOf([fun() ->
        std@async:delay(40, <<"slow">>)
    end, fun() ->
        std@async:delay(1, <<"fast">>)
    end]),
    '__bp_print'([<<"raceOf ", ('__bp_text'(Won))/binary>>]),
    InTime = std@async:timeout(fun() ->
        std@async:delay(1, <<"in time">>)
    end, 1000),
    '__bp_print'([<<"timeout ", ('__bp_text'((fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (<<"-">>) end end)(InTime)))/binary, "/", ('__bp_text'(std@async:errorText(InTime)))/binary>>]),
    Gate = std@async:newGate(),
    Late = std@async:timeout(fun() ->
        gated(Gate, <<"too late">>)
    end, 20),
    std@async:openGate(Gate),
    '__bp_print'([<<"timeout ", ('__bp_text'((fun(__BpR) -> case __BpR of {ok, __BpV1} -> __BpV1; _ -> (<<"-">>) end end)(Late)))/binary, "/", ('__bp_text'(std@async:errorText(Late)))/binary>>]),
    Shared = std@async:newGate(),
    Values = std@async:runAll([fun() ->
        gated(Shared, <<"waited">>)
    end, fun() ->
        handshake(Shared, Shared, <<"opened">>)
    end]),
    '__bp_print'([<<"gate ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Values)))))/binary>>]),
    Open = std@async:awaitGate(Shared, 10000),
    Closed = std@async:awaitGate(std@async:newGate(), 10),
    '__bp_print'([<<"awaitGate ", ('__bp_text'(erlang:atom_to_binary(Open)))/binary, " ", ('__bp_text'(erlang:atom_to_binary(Closed)))/binary>>]),
    Policy = {std@async@@RetryPolicy, 4, 100, 1.5, 300},
    Delays = lists:map(fun(Attempt) ->
        pauseText(Policy, Attempt)
    end, array_range(1, 6)),
    '__bp_print'([<<"nextDelay ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Delays)))))/binary>>]).

main() ->
    run().

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/std_async_on_every_target|*">>.

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

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

'__bp_priv__slow'(A0, A1) -> slow(A0, A1).

'__bp_priv__gated'(A0, A1) -> gated(A0, A1).

'__bp_priv__handshake'(A0, A1, A2) -> handshake(A0, A1, A2).

'__bp_priv__pauseText'(A0, A1) -> pauseText(A0, A1).

'__bp_priv__show'(A0, A1) -> show(A0, A1).

'__bp_priv__run'() -> run().
