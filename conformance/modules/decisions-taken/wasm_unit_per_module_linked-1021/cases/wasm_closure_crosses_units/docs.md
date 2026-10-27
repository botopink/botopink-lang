# wasm_closure_crosses_units

A function value crosses between two modules of a program: a closure made in `maker` called in `main`, one made in `main` called in `maker`, one passed to `std@array`'s `map`, a type's method taken as a value, and one capturing `maker`'s module `val` — the same answers on every target. On wasm each module is a unit of its own and a closure a GC value holding its entry's `funcref`, called by `call_ref` through the prelude's signature (decision 1055 (4)).
