# hooks_state_by_tree_place

Decision 816: the hooks' state lives in the node's scope cell, kept from one render to the next while
the same component stands at the same place, as React keeps a fiber. `render` runs `App` over one
root: the second render makes nothing; `if (logged) Counter("panel") else Counter("login")` are two
calls, so switching resets, and a place not met in a render is dropped (`made panel` again). The type
form `Badge(label: "b")` keeps its state as a `component fn` does (816 (3)).

[src/main.bp](src/main.bp)
