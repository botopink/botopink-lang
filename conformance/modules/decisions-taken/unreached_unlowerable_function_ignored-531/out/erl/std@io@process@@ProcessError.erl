-module(std@io@process@@ProcessError).
-export(['__bp_format'/1]).

'__bp_format'({std@io@process@@ProcessError__v__notfound, F0}) -> {variant, "ProcessError.NotFound", [{"command", F0}]};
'__bp_format'({std@io@process@@ProcessError__v__permissiondenied, F0}) -> {variant, "ProcessError.PermissionDenied", [{"command", F0}]};
'__bp_format'({std@io@process@@ProcessError__v__nosuchprocess, F0}) -> {variant, "ProcessError.NoSuchProcess", [{"pid", F0}]};
'__bp_format'({std@io@process@@ProcessError__v__unsupported, F0}) -> {variant, "ProcessError.Unsupported", [{"message", F0}]};
'__bp_format'({std@io@process@@ProcessError__v__other, F0}) -> {variant, "ProcessError.Other", [{"message", F0}]}.
