-module(bp_load_cases_member_reads_compiler_text@main@@Account).
-export([ruleText/1, '__bp_get'/2, '__bp_format'/1]).

ruleText(Self) ->
    (<<"always">>).

'__bp_get'(V, balance) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Account", [{"balance", erlang:element(2, V)}]}.
