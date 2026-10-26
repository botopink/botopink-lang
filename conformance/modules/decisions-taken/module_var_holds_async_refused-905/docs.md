# Decision 905 — The code refusing a module `var` whose type holds an `Async` is `module-var-holds-async`; its reach as built: at the written type else the name, "holds" read through type arguments, tuples and the fields of records and variants, never through a function type (a closure only); a module `val` holding an `Async` is accepted (547 (iii)).

[cases/module_var_async_direct/src/main.bp](cases/module_var_async_direct/src/main.bp)
[cases/module_var_async_in_array/src/main.bp](cases/module_var_async_in_array/src/main.bp)
[cases/module_var_async_in_record_field/src/main.bp](cases/module_var_async_in_record_field/src/main.bp)
