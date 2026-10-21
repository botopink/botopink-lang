# behavior_identity_by_module

The reference text this cell shows (from `conformance/docs.md`, § Union types, `unknown`, and `is`):

> A behavior's run-time identity is its declaration — the module's id and its name, the atom a type's is (`<package>@<path>@@<B>`): two same-named behaviors of two modules are two, the mark is the declared behavior's whatever the import calls it, and a type implementing `Sub extends Super` carries `Super`'s mark too (decision 831).

<!-- example: modules/decisions-taken/behavior_identity_by_module-831/run/src/cases/behavior_identity_by_module -->

Two behaviors named `Shown` in `a/m` and `b/m`, imported as `AShown` and `BShown`: `Ping` (`a/m`'s) is `AShown` and not `BShown`, `Pong` the reverse, `Echo` (implementing `AShown`) is `a/m`'s `Shown`, and `Bell` (implementing `Loud extends Shown`) is both `Loud` and `AShown`, by `is` and by a `case` type pattern, on every target.
