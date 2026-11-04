# component_root_run

Decisions 822, 825 (1): a root is `await run(App())` — `main`, a test, a request — whether the
component awaits or not; handed a scope, `run` runs over it and two runs over one root share its
contexts' tree; `resolve(c, scope, Place.none())` answers the value of a component that awaits
nothing as it is.

[src/main.bp](src/main.bp)
