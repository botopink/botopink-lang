# fn_expression_string_parameter

The reference text this cell shows (from `conformance/docs.md`, § Lambdas and method chains):

An untyped fn expression takes its parameter types from its use: called where it is written
(`(fn(s) { return s + "x"; })("a")`), passed to a parameter that expects `fn(string) -> string`,
or bound to a `val` and called, a `string` parameter writes its text on every target.
