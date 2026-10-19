# Decision 660 — (a): every module of every declared dependency is part of the program — it joins the build and its `compiler.init` executors join the init list whether or not anything imports it — and the init list is ordered by dependency resolution: a package that depends on nothing first, a package after every package it depends on, the ones with most dependencies last; two packages at the same level in the order their dependant's `botopink.json` lists them; inside a package, 580's order (modules in dependency order, declarations in source order).

The example has two modules, and `main` imports neither from the other. `plugin.bp` declares `web` under `#[register]`, whose `compiler.init` executor prints `registered web`. Since every module of the package is in the program, imported or not, that executor runs before `main`, and the program prints `registered web`, then `main`. A declared dependency's modules join the program the same way and their executors run first, a package after every package it depends on. A draft carries no manifest, so this example shows the package's own modules; the dependency half waits for the promoted cell's `botopink.json`.

Cells in this repository that also bear on it: `modules/decisions-taken/compiler_init_executor-615/cases/init_order_modules`, `modules/module/cases/module_init_order`, `modules/dependency/cases/dependency_module_level_print`.


[cases/dependency_init_without_import/src/main.bp](cases/dependency_init_without_import/src/main.bp)

Proved also by [init_order_packages](../dependency_target_missing_refused-676/cases/init_order_packages/src/main.bp)
