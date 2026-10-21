# use_all_resolves_a_list

Decision 827: `use all(cs)` runs each entry of a run-time list under `all`'s cell, in order, and
answers `T[]` — awaited as any `use c` is when an entry answered a task. `Slow` awaits; the list keeps
its order.

[src/main.bp](src/main.bp)
