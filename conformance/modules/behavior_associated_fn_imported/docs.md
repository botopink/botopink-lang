# behavior_associated_fn_imported

A behavior's associated `default fn` — one taking no `self` — is called
through the behavior's name, `Shape.unit()`, wherever the behavior is
imported, under an alias too, as in its own module:

`Shape.unit()` and `Area.scaled(7)` after `import {shapes.Shape}` and `import {shapes.Shape as Area}` — `1`, `7`.
