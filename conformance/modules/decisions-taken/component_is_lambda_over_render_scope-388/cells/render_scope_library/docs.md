# render_scope_library

Decision 388 (3) as 908 states it: the scope travels explicitly. A body resolves its children over its own cell (`use c`, `use all(cs)`, or `resolve(c, scope, key)` in a `{ scope -> … }` lambda), and a thunk kept for later over that scope reads the contexts it held, after the render returned.

[src/main.bp](src/main.bp)
