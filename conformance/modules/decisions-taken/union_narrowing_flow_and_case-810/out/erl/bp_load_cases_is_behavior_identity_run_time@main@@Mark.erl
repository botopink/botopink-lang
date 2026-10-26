-module(bp_load_cases_is_behavior_identity_run_time@main@@Mark).
-export([shown/1, '__bp_format'/1, '__bp_behaviors'/0]).

shown(Self) ->
    <<"mark">>.

'__bp_format'(bp_load_cases_is_behavior_identity_run_time@main@@Mark__v__plain) -> {variant, "Mark.Plain", []};
'__bp_format'({bp_load_cases_is_behavior_identity_run_time@main@@Mark__v__named, F0}) -> {variant, "Mark.Named", [{"text", F0}]}.

'__bp_behaviors'() -> [bp_load_cases_is_behavior_identity_run_time@main@@Shown].
