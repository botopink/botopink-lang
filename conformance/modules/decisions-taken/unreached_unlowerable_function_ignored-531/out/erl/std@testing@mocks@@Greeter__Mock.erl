-module(std@testing@mocks@@Greeter__Mock).
-export([greet/2, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

greet(Self, Name) ->
    (fun(OzId__, OzM__, OzKs__, OzDef__) -> OzP__ = case get('__bp_mocks_pending') of undefined -> []; OzL1__ -> OzL1__ end, put('__bp_mocks_pending', []), OzMs__ = case length(OzP__) =:= length(OzKs__) of true -> OzP__; false -> [{<<"eq">>, OzK__} || OzK__ <- OzKs__] end, OzMatch__ = fun(OzMx__, OzKx__) -> length(OzMx__) =:= length(OzKx__) andalso lists:all(fun({{OzKind__, OzKey__}, OzArg__}) -> OzKind__ =:= <<"any">> orelse OzKey__ =:= OzArg__ end, lists:zip(OzMx__, OzKx__)) end, OzCalls__ = case get('__bp_mocks_calls') of undefined -> []; OzL2__ -> OzL2__ end, case erase('__bp_mocks_verify') of undefined -> put('__bp_mocks_calls', OzCalls__ ++ [{OzId__, OzM__, OzKs__, OzMs__}]), OzHit__ = [OzSt__ || {OzSId__, OzSM__, OzSMs__, _, _} = OzSt__ <- lists:reverse(case get('__bp_mocks_stubs') of undefined -> []; OzL3__ -> OzL3__ end), OzSId__ =:= OzId__, OzSM__ =:= OzM__, OzMatch__(OzSMs__, OzKs__)], case OzHit__ of [] -> OzDef__; [{_, _, _, return, OzRv__} | _] -> OzRv__; [{_, _, _, throw, OzMsg__} | _] -> erlang:error(OzMsg__) end; OzSpec__ -> OzCount__ = length([x || {OzCId__, OzCM__, OzCKs__, _} <- OzCalls__, OzCId__ =:= OzId__, OzCM__ =:= OzM__, OzMatch__(OzMs__, OzCKs__)]), case (case OzSpec__ of -1 -> OzCount__ >= 1; _ -> OzCount__ =:= OzSpec__ end) of true -> OzDef__; false -> erlang:error(iolist_to_binary([<<"mocks.verify: ">>, OzM__, <<" - expected ">>, case OzSpec__ of -1 -> <<"at least 1">>; _ -> [<<"exactly ">>, integer_to_binary(OzSpec__)] end, <<" matching call(s), got ">>, integer_to_binary(OzCount__)])) end end end)(erlang:element(2, Self), <<"greet">>, [iolist_to_binary(io_lib:format("~0tp", [Name]))], <<"">>).

'__bp_get'(V, '__id') -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Greeter.Mock", [{"__id", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [std@testing@mocks@@Greeter].
