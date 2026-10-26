# template_in_module_val_lambda

The reference text this cell shows (from `conformance/docs.md`, § Functions expanded at their call):

> A template call expands wherever an expression may stand (decision 425): a
> function's or a type's method body, a destructuring initializer
> (`val #(n, total) = f "…";`), a lambda (one a module-level `val` holds
> included), an argument, a record field's or a
> parameter's default (each call that leaves it out gets the expansion), a
> `case` arm.
