-module(std@io@process@@Child).
-export([wait/1, kill/2, forwardSignals/1, '__bp_get'/2, '__bp_format'/1]).

%% @Async — eager lowering
wait(Self) ->
    (fun(__P) -> case get({bp_child_status, __P}) of undefined -> __L = fun __F() -> receive {__Q, {data, __D}} when __Q =:= __P -> case unicode:characters_to_binary(__D) of __U when is_binary(__U) -> io:put_chars(__U); _ -> io:put_chars(unicode:characters_to_binary(__D, latin1)) end, __F(); {__Q, {exit_status, __S}} when __Q =:= __P -> put({bp_child_status, __P}, __S), __S end end, __L(); __S -> __S end end)(erlang:element(3, Self)).

kill(Self, S) ->
    case (fun(__P, __Name) -> case erlang:port_info(__P, os_pid) of {os_pid, __Os} -> __Out = os:cmd("kill -" ++ binary_to_list(binary:part(__Name, 3, byte_size(__Name) - 3)) ++ " " ++ integer_to_list(__Os) ++ " 2>&1"), case string:find(__Out, "No such process") of nomatch -> case __Out of [] -> {ok, 0}; _ -> {error, unicode:characters_to_binary([<<"other|">>, __Out])} end; _ -> {error, <<"gone|">>} end; undefined -> {error, <<"gone|">>} end end)(erlang:element(3, Self), std@io@process:signalName(S)) of
        {ok, _} ->
            {ok, undefined};
        {error, M} ->
            {error, std@io@process:processError(<<"">>, erlang:element(2, Self), M)}
    end.

forwardSignals(Self) ->
    try
        H = erlang:element(3, Self),
        lists:foreach(fun(S) ->
            Name = std@io@process:signalName(S),
            case (fun(__Name, __F) -> __Sig = if __Name =:= <<"SIGTERM">> -> sigterm; __Name =:= <<"SIGHUP">> -> sighup; __Name =:= <<"SIGWINCH">> -> sigwinch; true -> unsupported end, case __Sig of unsupported -> {error, iolist_to_binary([<<"unsupported|">>, __Name, <<" cannot be caught on the Erlang VM">>])}; _ -> try case code:is_loaded(bp_signal_handler) of false -> __Src = "-module(bp_signal_handler). -behaviour(gen_event). -export([init/1, handle_event/2, handle_call/2]). init(S) -> {ok, S}. handle_event(E, S) -> [F() || F <- persistent_term:get({bp_signal, E}, [])], {ok, S}. handle_call(_, S) -> {ok, ok, S}.", {ok, __Toks, _} = erl_scan:string(__Src), __Split = fun __Sp([], []) -> []; __Sp([], __A) -> [lists:reverse(__A)]; __Sp([{dot, _} = __D | __T], __A) -> [lists:reverse([__D | __A]) | __Sp(__T, [])]; __Sp([__X | __T], __A) -> __Sp(__T, [__X | __A]) end, __Forms = [begin {ok, __Fm} = erl_parse:parse_form(__Ts), __Fm end || __Ts <- __Split(__Toks, [])], {ok, __M, __B} = compile:forms(__Forms, [binary]), {module, _} = code:load_binary(__M, "bp_signal_handler.erl", __B); _ -> ok end, case lists:member(bp_signal_handler, gen_event:which_handlers(erl_signal_server)) of true -> ok; false -> _ = (catch gen_event:delete_handler(erl_signal_server, erl_signal_handler, [])), ok = gen_event:add_handler(erl_signal_server, bp_signal_handler, []) end, persistent_term:put({bp_signal, __Sig}, persistent_term:get({bp_signal, __Sig}, []) ++ [__F]), ok = os:set_signal(__Sig, handle), {ok, 0} catch _:__E -> {error, iolist_to_binary([<<"other|">>, io_lib:format("~tp", [__E])])} end end end)(Name, fun() ->
                (fun(__P, __Name) -> case erlang:port_info(__P, os_pid) of {os_pid, __Os} -> __Out = os:cmd("kill -" ++ binary_to_list(binary:part(__Name, 3, byte_size(__Name) - 3)) ++ " " ++ integer_to_list(__Os) ++ " 2>&1"), case string:find(__Out, "No such process") of nomatch -> case __Out of [] -> {ok, 0}; _ -> {error, unicode:characters_to_binary([<<"other|">>, __Out])} end; _ -> {error, <<"gone|">>} end; undefined -> {error, <<"gone|">>} end end)(H, Name)
            end) of
                {ok, _} ->
                    undefined;
                {error, M} ->
                    E = std@io@process:processError(<<"">>, erlang:element(2, Self), M),
                    case E of
                        {std@io@process@@ProcessError__v__unsupported, _} ->
                            undefined;
                        _ ->
                            erlang:throw({'__bp_try', {error, E}})
                    end
            end
        end, [std@io@process@@Signal__v__int, std@io@process@@Signal__v__term, std@io@process@@Signal__v__hup, std@io@process@@Signal__v__winch]),
        {ok, undefined}
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

'__bp_get'(V, pid) -> erlang:element(2, V);
'__bp_get'(V, handle) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Child", [{"pid", erlang:element(2, V)}, {"handle", erlang:element(3, V)}]}.
