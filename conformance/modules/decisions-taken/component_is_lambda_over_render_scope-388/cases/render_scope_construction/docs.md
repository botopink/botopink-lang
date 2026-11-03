# render_scope_construction

Decisions 809 (8), 811 — a `Scope` is opaque: made only by `Scope.root()`, a cell's `childAt` and `detach`. Writing its constructor anywhere else, as here, is refused at the call (`opaque-construction`).

[src/main.bp](src/main.bp)
