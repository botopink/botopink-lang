# Decision 592 — (e), a counter-proposal: a file is a module, and the build has a layer of its own.

The example is a package of five files, and each is a module named by its path: `main`, `pages.home`, `pages.about`, `internal.text` and `comptime.route`. No `lib.bp` exists and no file declares another with `mod`. `main.bp` is the executable's entry and holds `pub fn main()`, and no module imports it.

[draft/comptime/route.bp](draft/comptime/route.bp) is the build layer. It is analysed before every other module and imports only std. The decorator `route` is declared there, as every decorator and template must be, and it records a typed `Route` meta.

[draft/pages/home.bp](draft/pages/home.bp) and [draft/pages/about.bp](draft/pages/about.bp) import each other, so they form one block. The headers of both modules are registered before either body is checked, so each calls the other's `path()`. `home.visits` is a module-level `val` that reads `about.base` across the cycle. At run time it is a memoised getter, so the order in which the two modules load does not matter.

[draft/internal/text.bp](draft/internal/text.bp) sits under `internal/`, so it is private to the package: `pages.home` imports `shout` from it, and another package could not. Every other `pub` item is the package's API.

The program prints `HOME! links /about`, `about links /` and `42`. A value needing itself across the two modules (`pub val base = home.visits + 1` in `about.bp`) would be the one order refusal, `dependency loop`, located.

Cells in this repository that bear on it: `modules/modules/cells/modules`, `modules/two/run/src/cases/two_modules`, `modules/import/cells/import_module_paths`, `modules/module/cases/module_init_order`, `modules/pub/cells/pub_val_across_modules`, `modules/decisions-taken/shorthand_import_refused-337/cases/private_module_through_namespace`.

[draft/main.bp](draft/main.bp)
