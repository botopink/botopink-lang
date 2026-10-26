-module(std@io@http@@HttpError).
-export(['__bp_format'/1]).

'__bp_format'(std@io@http@@HttpError__v__notallowedonhost) -> {variant, "HttpError.NotAllowedOnHost", []};
'__bp_format'({std@io@http@@HttpError__v__network, F0}) -> {variant, "HttpError.Network", [{"message", F0}]};
'__bp_format'(std@io@http@@HttpError__v__timeout) -> {variant, "HttpError.Timeout", []}.
