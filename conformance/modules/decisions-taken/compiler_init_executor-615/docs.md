# Decision 615 — `compiler.compile` is renamed `compiler.init`: `init(syntax executor: fn())` puts the executor in the program's init list, at the annotated declaration's position (580), to run once before `main`.

[cells/init_order_modules/src/main.bp](cells/init_order_modules/src/main.bp)
[cells/init_output_outside_decorator/src/main.bp](cells/init_output_outside_decorator/src/main.bp)
