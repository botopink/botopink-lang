# Decision 373 — No new `@emit` site.

The decorator `entity`, declared in the build layer ([draft/comptime/model.bp](draft/comptime/model.bp)), writes everything it produces under the path of the type it annotates, and nothing as a free name of the module. On `City` it does four things. It records the typed meta `Entity(table: "cities")`, read back by `compiler.typeInfo(City).meta(Entity)`. It adds the member `City.table()`. It adds the associated type `City.Columns`, built here as `City.Columns(id: "1", name: "Lisbon")`. It registers `City` with a `compiler.init` executor that runs before `main`. The executor calls `record`, a name of the decorator's own module, and gets the declaration's name as a literal read at build.

No `@emit` exists to write a module-level `val` or `fn` beside the type; the generated functions of old are typed members like `table`. `main` reaches each output through `City` or through the run-time registry, and imports nothing the decorator generated.

The program prints `cities`, `Lisbon`, `cities` and `City`.

Cells in this repository that bear on it: `modules/decisions-taken/decorator_four_output_places-216/run/src/cases/decorator_add_type`, `modules/decisions-taken/decorator_meta_keyed_by_type-298/cells/meta_typed`, `modules/decisions-taken/no_declaration_files_compiler_value-575/cells/init_executor_before_main`, `modules/decisions-taken/decorator_invocations_independent-343/refused/src/cases/decorator_writes_module_var`.

[draft/main.bp](draft/main.bp)
