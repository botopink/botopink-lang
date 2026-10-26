# Decision 412 — A `comptime` variadic is one expression of the array — `comptime ..xs: @Expr<T[]>`.

The decorator `index`, declared in the build layer ([draft/comptime/index.bp](draft/comptime/index.bp)), takes its columns as a `comptime` variadic: `comptime ..fields: compiler.Field<T>[]`. Its type is the whole array, not an array of separate parameters. Each argument written at the annotation, `.name` and `.state`, is checked against `compiler.Field<City>`, so a `.zip` that `City` does not have is refused at that argument. In the body `fields` is the array itself, mapped to the names it records. The program reads the recorded `Index` back under `comptime` and prints `name,state`.

Cells in this repository that bear on it: `modules/decisions-taken/variadic_last_parameter-267/run/src/cases/variadic_parameter`, `modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_field_type`.

[draft/main.bp](draft/main.bp)
