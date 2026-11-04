# place_written_by_the_call

Decision 820: each written call answering a component answers its value carrying its place; `use c`,
the renderer and the root pass `Place.none()`, which keeps it, and a hand `Place.key(k)` replaces the
item half only. `h`, `Card(…)` and the reversed list keep their memos across renders; `Header()` made
in `main` runs at a fresh root's place (820 (3)).

[src/main.bp](src/main.bp)
