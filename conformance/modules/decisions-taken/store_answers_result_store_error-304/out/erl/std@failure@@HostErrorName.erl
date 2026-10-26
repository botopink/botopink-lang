-module(std@failure@@HostErrorName).
-export(['__bp_format'/1]).

'__bp_format'(std@failure@@HostErrorName__v__error) -> {variant, "HostErrorName.Error", []};
'__bp_format'(std@failure@@HostErrorName__v__throw) -> {variant, "HostErrorName.Throw", []};
'__bp_format'(std@failure@@HostErrorName__v__exit) -> {variant, "HostErrorName.Exit", []}.
