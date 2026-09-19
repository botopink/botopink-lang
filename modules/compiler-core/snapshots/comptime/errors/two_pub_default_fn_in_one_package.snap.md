----- SOURCE CODE
pub default fn one(comptime q: @Expr<string>) -> @ExprCustom<i32> { return q.build("0"); }
pub default fn two(comptime q: @Expr<string>) -> @ExprCustom<i32> { return q.build("0"); }

----- ERROR
error: a package declares at most one `pub default mod` and one `pub default fn`

  hint: Remove the duplicate default declaration; a package has a single default module and handler.
