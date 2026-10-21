# fn_expr_optional_param_null

Decision 408: with no type of its own position, a typed function expression's written types are the function's. A
parameter written as an optional — an optional array `?Holder[]`, an optional function `?fn(i32) -> i32` — takes `null`
as it takes a value: `one(null)` answers `1`, `two(null)` answers `0`, and `three([…])`, its argument present, `3`.
