# module_var_in_dependency

A module-level `var` declared in a dependency's module is one value per execution context, read and written through that module's functions, on every target: two bumps print `2`.
