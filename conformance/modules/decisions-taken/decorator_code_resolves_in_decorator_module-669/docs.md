# Decision 669 — Code a decorator writes resolves in the decorator's module, a type it builds included; the one way to a caller's names is `compiler.lookup`.

The example's `main` imports the decorator `stamped` and nothing else from `stamp`. `stamped` adds to `Order` the static member `stampAt`, whose body builds a `Clock` and calls the private `stampOf`. Both names resolve in `stamp.bp`, where the member is written, so `main` neither imports nor sees them, and `Order.stampAt(3)` answers `t3`. The program prints `t3` and `7`.

Cells in this repository that also bear on it: `modules/decisions-taken/decorator_four_output_places-216/cases/decorator_add_member_import`.


[cases/decorator_member_reaches_decorator_imports/src/main.bp](cases/decorator_member_reaches_decorator_imports/src/main.bp)
