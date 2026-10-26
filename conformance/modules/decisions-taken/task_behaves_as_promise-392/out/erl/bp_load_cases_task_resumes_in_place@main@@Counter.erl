-module(bp_load_cases_task_resumes_in_place@main@@Counter).
-export([bump/2, '__bp_get'/2, '__bp_format'/1]).

%% @Async — eager lowering
bump(Self, By) ->
    Step = (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(1, By),
    '__bp_add'(erlang:element(2, Self), Step).

'__bp_get'(V, base) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Counter", [{"base", erlang:element(2, V)}]}.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.
