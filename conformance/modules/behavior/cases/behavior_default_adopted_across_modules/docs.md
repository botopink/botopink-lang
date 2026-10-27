# behavior_default_adopted_across_modules

A type implementing a behavior of another module adopts the behavior's
instance `default fn`s, and those of what it extends, as a type implementing a
behavior of its own module does; a method of the same name the type writes
wins:

`Sq(n: 3).twice()` and `.shout()` (from `Named`, which `Shape` extends), `Big`'s own `twice`, and a value typed `Shape` — `18`, `sq!`, `1000`, `8`, `10`.
