# wasm_val_methods_cross_units

`config` declares a module `val` whose initialiser prints, a type `Box` with its own method `doubled` and the method `name` of the behavior `Named` it implements; `reader` and `main` both read the `val` and call the methods. The initialiser runs once, when `config` loads, whoever reads the `val` — the same answers on every target. On wasm each module is a unit of its own: `config` exports an accessor of the `val`, set once in its own `__bp_init`, and its methods, which the other units import instead of linking their bodies (decision 1055 (6), (8)).
