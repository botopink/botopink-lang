-module(bp_load_cases_async_block_all_of@main@@Batch).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, task) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Batch", [{"task", erlang:element(2, V)}]}.
