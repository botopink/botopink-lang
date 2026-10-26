-module(bp_load_cases_template_lookup_decl_members@main@@Counter).
-export(['of'/2, '__bp_get'/2, '__bp_format'/1]).

'of'(Start, Step) ->
    {bp_load_cases_template_lookup_decl_members@main@@Counter, '__bp_int'((Start + Step), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:15:33">>)}.

'__bp_get'(V, n) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Counter", [{"n", erlang:element(2, V)}]}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
