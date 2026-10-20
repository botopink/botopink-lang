# fn_return_missing_fn_expr

Decision 622, with 408: a typed `fn` expression writes its return type as a declaration does. `fn(n: i32) { … }` writes
no `->` and is refused at its `fn`, `fn-return-missing`, whatever the position's type says.
