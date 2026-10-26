-module(std@compiler@@Module).
-export(['of'/3, name/1, path/1, buildOutput/1, run/1, captureOpen/0, captureClose/1, '__bp_get'/2, '__bp_format'/1]).

'of'(Name, Path, BuildOutput) ->
    {std@compiler@@Module, Name, Path, BuildOutput}.

name(Self) ->
    erlang:element(2, Self).

path(Self) ->
    erlang:element(3, Self).

buildOutput(Self) ->
    erlang:element(4, Self).

run(Self) ->
    {error, {std@compiler@@RunFailure, std@compiler@@RunFailureKind__v__abort, <<"Module.run: every call is lowered to the loaded main">>, <<"">>}}.

captureOpen() ->
    (fun() -> BpCapOld = erlang:group_leader(), BpCapPid = erlang:spawn(fun() -> (fun BpCapLoop(BpCapAcc) -> receive {io_request, BpCapFrom, BpCapAs, BpCapReq} -> {BpCapReply, BpCapAcc2} = (fun BpCapDo(BpCapR, BpCapA) -> case BpCapR of {put_chars, _, BpCapM, BpCapF, BpCapArgs} -> {ok, [BpCapA, erlang:apply(BpCapM, BpCapF, BpCapArgs)]}; {put_chars, BpCapM, BpCapF, BpCapArgs} -> {ok, [BpCapA, erlang:apply(BpCapM, BpCapF, BpCapArgs)]}; {put_chars, _, BpCapChars} -> {ok, [BpCapA, BpCapChars]}; {put_chars, BpCapChars} -> {ok, [BpCapA, BpCapChars]}; {requests, BpCapRs} -> lists:foldl(fun(BpCapOne, {_, BpCapIn}) -> BpCapDo(BpCapOne, BpCapIn) end, {ok, BpCapA}, BpCapRs); _ -> {{error, enotsup}, BpCapA} end end)(BpCapReq, BpCapAcc), BpCapFrom ! {io_reply, BpCapAs, BpCapReply}, BpCapLoop(BpCapAcc2); {bp_capture_take, BpCapTo, BpCapRef} -> BpCapTo ! {BpCapRef, unicode:characters_to_binary(BpCapAcc)} end end)([]) end), erlang:group_leader(BpCapPid, erlang:self()), {bp_capture, BpCapOld, BpCapPid} end)().

captureClose(Open) ->
    (fun({bp_capture, BpCapOld2, BpCapPid2}) -> erlang:group_leader(BpCapOld2, erlang:self()), BpCapRef2 = erlang:make_ref(), BpCapPid2 ! {bp_capture_take, erlang:self(), BpCapRef2}, receive {BpCapRef2, BpCapText} -> BpCapText end end)(Open).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, path) -> erlang:element(3, V);
'__bp_get'(V, buildOutput) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Module", [{"name", erlang:element(2, V)}, {"path", erlang:element(3, V)}, {"buildOutput", erlang:element(4, V)}]}.
