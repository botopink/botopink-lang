-module(bp_load_cases_for_loop_sources@main@@YieldStep).
-export(['__bp_format'/1]).

'__bp_format'({bp_load_cases_for_loop_sources@main@@YieldStep__v__yield, F0}) -> {variant, "YieldStep.Yield", [{"value", F0}]};
'__bp_format'(bp_load_cases_for_loop_sources@main@@YieldStep__v__done) -> {variant, "YieldStep.Done", []}.
