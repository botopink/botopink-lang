-module(std@collections@@Order).
-export(['__bp_format'/1]).

'__bp_format'(std@collections@@Order__v__lt) -> {variant, "Order.Lt", []};
'__bp_format'(std@collections@@Order__v__eq) -> {variant, "Order.Eq", []};
'__bp_format'(std@collections@@Order__v__gt) -> {variant, "Order.Gt", []}.
