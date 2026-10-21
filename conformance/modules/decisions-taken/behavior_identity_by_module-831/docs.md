# Decision 831 — A behavior's run-time identity is its declaration — the module's id and its name, the atom a type's is (`<package>@<path>@@<B>`); one identity, each target's own representation; no counter crosses a package; amends 810 (1), 23 kept.

A behavior has no value of its own: `v is B` asks whether `v`'s type implements `B`, and the mark each implementing
type carries names the behavior by its declaration — the module that declares it and its name, as a type's atom does.
Two behaviors named `Shown` of two modules are two, a type implementing an imported behavior under an alias carries the
declared behavior's mark, and a type implementing `Loud extends Shown` carries `Shown`'s mark too
(`behavior_identity_by_module`).

[run/src/cases/behavior_identity_by_module/mod.bp](run/src/cases/behavior_identity_by_module/mod.bp)
