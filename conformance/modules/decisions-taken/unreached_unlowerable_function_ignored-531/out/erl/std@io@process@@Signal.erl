-module(std@io@process@@Signal).
-export(['__bp_format'/1]).

'__bp_format'(std@io@process@@Signal__v__int) -> {variant, "Signal.Int", []};
'__bp_format'(std@io@process@@Signal__v__term) -> {variant, "Signal.Term", []};
'__bp_format'(std@io@process@@Signal__v__hup) -> {variant, "Signal.Hup", []};
'__bp_format'(std@io@process@@Signal__v__winch) -> {variant, "Signal.Winch", []}.
