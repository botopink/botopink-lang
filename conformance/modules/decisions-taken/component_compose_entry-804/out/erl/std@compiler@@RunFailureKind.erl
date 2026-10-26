-module(std@compiler@@RunFailureKind).
-export(['__bp_format'/1]).

'__bp_format'(std@compiler@@RunFailureKind__v__failed) -> {variant, "RunFailureKind.Failed", []};
'__bp_format'(std@compiler@@RunFailureKind__v__abort) -> {variant, "RunFailureKind.Abort", []};
'__bp_format'(std@compiler@@RunFailureKind__v__refused) -> {variant, "RunFailureKind.Refused", []};
'__bp_format'(std@compiler@@RunFailureKind__v__excluded) -> {variant, "RunFailureKind.Excluded", []}.
