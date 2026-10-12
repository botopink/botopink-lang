# self_tail_recursion_nullish

A function calling itself in tail position after a `??` in its body does not grow the stack: 20 000 calls answer on every target.
