# Decision 968 — std's `Scope` keeps the tree of cells by place: a component's cell is found again at its place from one render to the next and dropped when the place is not met; it holds the hooks' slots of every value-answering `use`, in the order written, and takes its parent's contexts anew at each render; `#[key(expr)]` is written at the call; `{ component -> … }` is 574's factory, never a component; restates what stands of 816, 817 and 818 under 966, replacing them.

A cell takes its parent's contexts, and a `use provide` writes the providing body's own cell alone (decisions 908,
966 (5), 968 (2)/(3), 812 (1)). What a body provides reaches only what is resolved inside that body. Three cases pin
how a kept scope reads (decision 809 (8)): two bodies resolved over one cell opened outside them are siblings, and the
second reads the default; a scope kept inside the providing body reads the provide; a child resolved outside the
providing body reads the default.

[cases/sibling_bodies_over_pre_opened_cell/src/main.bp](cases/sibling_bodies_over_pre_opened_cell/src/main.bp)
[cases/scope_kept_inside_providing_body/src/main.bp](cases/scope_kept_inside_providing_body/src/main.bp)
[cases/child_resolved_outside_providing_body/src/main.bp](cases/child_resolved_outside_providing_body/src/main.bp)
