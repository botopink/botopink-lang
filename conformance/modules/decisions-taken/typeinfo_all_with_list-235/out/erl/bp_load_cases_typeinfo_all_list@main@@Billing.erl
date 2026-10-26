-module(bp_load_cases_typeinfo_all_list@main@@Billing).
-export([make/0, '__bp_get'/2, '__bp_format'/1]).

make() ->
    <<"Billing">>.

'__bp_get'(V, rate) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Billing", [{"rate", erlang:element(2, V)}]}.
