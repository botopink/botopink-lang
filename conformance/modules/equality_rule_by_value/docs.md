# equality_rule_by_value

Decision 348: `==` compares records, tuples, lists and enum variants by value, recursively, on every target; a method
named `equals` has no role in it. A tuple literal is an operand like any other, so `#(1, [a, b]) == …` compares the two
tuples — it used to end the expression after the literal and refuse the `==`.

It prints `true`, `false`, `true`, `true`, `false`, `true` and `true`.
