# meta_expr_field_literal

Decision 576 (12): a meta record's field written `@Expr<T>` (370 (1)) is written `T`: it holds a tree when filled from an `expr` (575 (4)'s tree rule), no field modifier. The refusal `decorator-meta-expr-arg` of a literal is gone: the decorator records `Check(message: "fixed")`, and the type carries one `Check`.
